import Foundation

/// Ask every server for one account; as soon as `r` have answered,
/// return the reply with the HIGHEST version. nil if fewer than r answer.
nonisolated func quorumRead(accountID: Int,
                            from servers: [ReplicaServer],
                            r: Int,
                            over network: some Network) async -> Account? {
    await withTaskGroup(of: Account?.self) { group in
        for server in servers {
            group.addTask {
                try? await network.send(to: server) { try await $0.read(accountID: accountID) }
            }
        }
        var replies: [Account] = []
        for await reply in group {
            // TODO (you):
            // - if reply isn't nil, append it to replies
            // - once replies.count reaches r: group.cancelAll(), then
            //   return the reply with the highest version
            
            if let reply{
                replies.append(reply)
            }
            if replies.count >= r {
                group.cancelAll()
                return replies.max(by: { $0.version < $1.version })
            }
        }
        return nil
    }
}

/// Send the account to every server; return true once `w` have acknowledged.
/// The rest of the writes KEEP GOING in the background.
nonisolated func quorumWrite(_ account: Account,
                             to servers: [ReplicaServer],
                             w: Int,
                             over network: some Network) async -> Bool {
    let (results, continuation) = AsyncStream.makeStream(of: Bool.self)
    for server in servers {
        Task {
            let ok = (try? await network.send(to: server) { try await $0.write(account) }) != nil
            continuation.yield(ok)
        }
    }
    var acks = 0
    var replies = 0
    for await ok in results {
        replies += 1
        if ok { acks += 1 }
        if acks >= w { return true }
        if replies == servers.count { break }
    }
    return false
}

/// One transfer = quorum-read both accounts, compute new balances, quorum-write both.
nonisolated func quorumTransfer(from fromID: Int, to toID: Int, amount: Int,
                                servers: [ReplicaServer], r: Int, w: Int,
                                over network: some Network) async -> Bool {
    let limit: Duration = .milliseconds(500)

    guard var from = await withTimeout(limit, { await quorumRead(accountID: fromID, from: servers, r: r, over: network) }),
          var to = await withTimeout(limit, { await quorumRead(accountID: toID, from: servers, r: r, over: network) }),
          from.balance >= amount else { return false }

    from.balance -= amount
    from.version += 1
    to.balance += amount
    to.version += 1

    let newFrom = from, newTo = to     // freeze as `let` so concurrent closures can capture them
    async let wroteFrom = withTimeout(limit) { await quorumWrite(newFrom, to: servers, w: w, over: network) }
    async let wroteTo = withTimeout(limit) { await quorumWrite(newTo, to: servers, w: w, over: network) }
    let (a, b) = await (wroteFrom, wroteTo)
    return (a ?? false) && (b ?? false)     // nil (timed out) counts as failure
}
