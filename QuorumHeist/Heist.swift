import Foundation

/// One copy of an account, as seen on one server.
nonisolated struct Copy: Hashable, Codable {
    let server: String
    let balance: Int
}

/// "Account 3, version 5", used as a dictionary key.
nonisolated struct ConflictKey: Hashable, Codable {
    let accountID: Int
    let version: Int
}

nonisolated enum AnomalyKind: String, Codable {
    case conflict        // same account + same version, different balances
    case moneyChanged    // total money supply moved
}

nonisolated struct Anomaly: Identifiable, Codable, Equatable {
    var id = UUID()
    let transferNumber: Int
    let kind: AnomalyKind
    let message: String
}

/// Find every (account, version) that has MORE THAN ONE different balance across servers.
func findConflicts(in nodes: [ServerNode]) -> [ConflictKey: [Copy]] {
    var groups: [ConflictKey: [Copy]] = [:]

    //  fill `groups`.
    // For every node, for every account in that node's ledger:
    //   build its ConflictKey (account id + version),
    //   and add a Copy (node name + balance) to that key's list.
    
    for node in nodes{
        for account in node.ledger.accounts{
            let key = ConflictKey(accountID: account.id, version: account.version)
            let copy = Copy(server: node.name, balance: account.balance)
            groups[key,default: []].append(copy)
        }
                
    }

    //  step 2: return only the groups that disagree,
    // meaning their copies contain more than one DIFFERENT balance.
    return groups.filter { key, copies in
        Set(copies.map(\.balance)).count > 1
    }
}
