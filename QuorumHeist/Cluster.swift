import Foundation
import Observation

@Observable
final class Cluster {
    var nodes: [ServerNode]
    var packets: [Packet] = []
    var r = 3
    var w = 3
    var lastResult: Bool?
    var partitioned = false
    var lastClient: Int?
    var anomalies: [Anomaly] = []
    
    var alarm = false
    @ObservationIgnored private var reported: Set<ConflictKey> = []
    @ObservationIgnored private var transferCount = 0
    
    private let sideA: Set<Int> = [0, 1]      // A, B
    private let sideB: Set<Int> = [2, 3, 4]   // C, D, E
    

    @ObservationIgnored private var servers: [ReplicaServer]
//    @ObservationIgnored private let network = SimulatedNetwork()

    init() {
        let start = makeStartingCluster()
        nodes = start
        servers = start.map { ReplicaServer(id: $0.id, name: $0.name, ledger: $0.ledger) }
    }

    var healthyCount: Int { nodes.count(where: { $0.status.isUp }) }

    /// The "real" money: for each account, trust the highest-version copy anywhere.
    var moneySupply: Int {
        (1...10).reduce(0) { sum, id in
            let newest = nodes
                .compactMap { node in node.ledger.accounts.first { $0.id == id } }
                .max { $0.version < $1.version }
            return sum + (newest?.balance ?? 0)
        }
    }

    func toggle(nodeID: Int) {
        guard let i = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        if nodes[i].status.isUp {
            nodes[i].status = .crashed(since: .now)
        } else {
            nodes[i].status = .healthy
        }
        let server = servers[i]
        let up = nodes[i].status.isUp
        Task { await server.setUp(up) }
    }

    func reset() {
        let start = makeStartingCluster()
        nodes = start
        servers = start.map { ReplicaServer(id: $0.id, name: $0.name, ledger: $0.ledger) }
        packets = []
        lastResult = nil
        lastClient = nil
        anomalies = []
        reported = []
        transferCount = 0
    }

    @discardableResult
    func sendTransfers(_ count: Int) async -> Run {
        let clock = ContinuousClock()
        var latencies: [Double] = []
        var committed = 0
        let conflictsAtStart = reported.count

        for i in 0..<count {
            let client = i % 2
            var net = SimulatedNetwork()
            if partitioned {
                net.unreachable = (client == 0) ? sideB : sideA
            }
            let fromID = Int.random(in: 1...10)
            var toID = fromID
            while toID == fromID { toID = Int.random(in: 1...10) }

            let supplyBefore = moneySupply
            let before = nodes.map(\.applied)
            let wave = servers.indices.map { Packet(target: $0) }
            packets.append(contentsOf: wave)

            let started = clock.now                                   // ⏱ start
            let ok = await quorumTransfer(from: fromID, to: toID,
                                          amount: Int.random(in: 1...50),
                                          servers: servers, r: r, w: w, over: net)
            latencies.append((clock.now - started) / .milliseconds(1)) // ⏱ stop, in ms
            if ok { committed += 1 }
            lastResult = ok
            lastClient = client

            await refresh()
            transferCount += 1
            checkForHeist(supplyBefore: supplyBefore)

            for packet in wave {
                let delivered = nodes[packet.target].applied > before[packet.target]
                setState(of: packet.id, to: delivered ? .delivered : .dropped)
            }
            let ids = Set(wave.map(\.id))
            Task {
                try? await Task.sleep(for: .milliseconds(400))
                self.packets.removeAll { ids.contains($0.id) }
            }
        }
        try? await Task.sleep(for: .milliseconds(300))
        await refresh()

        return Run(r: r, w: w, partitioned: partitioned,
                   committed: committed, transfers: count,
                   p50: percentile(latencies, 50),
                   p95: percentile(latencies, 95),
                   p99: percentile(latencies, 99),
                   conflicts: reported.count - conflictsAtStart)
    }
    
    private func checkForHeist(supplyBefore: Int) {
        let conflicts = findConflicts(in: nodes)
        var foundNewConflict = false

        for (key, copies) in conflicts where !reported.contains(key) {
            reported.insert(key)
            foundNewConflict = true
            let detail = copies.map { "\($0.server)=$\($0.balance)" }.joined(separator: ", ")
            log(.conflict, "Account \(key.accountID) has two different v\(key.version)s: \(detail)")
        }

        let supplyAfter = moneySupply
        if supplyAfter != supplyBefore {
            let delta = supplyAfter - supplyBefore
            let why = foundNewConflict ? "new conflicting writes" : "no new conflict: late write, earlier conflict, or half-done transfer"
            log(.moneyChanged, "Money supply \(delta > 0 ? "+" : "")\(delta) → $\(supplyAfter) (\(why))")
        }
    }

    private func log(_ kind: AnomalyKind, _ message: String) {
        anomalies.insert(Anomaly(transferNumber: transferCount, kind: kind, message: message), at: 0)
        alarm = true
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            self.alarm = false
        }
    }

    func exportLog() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        guard let data = try? encoder.encode(anomalies) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }
    private func setState(of id: UUID, to state: PacketState) {
        if let i = packets.firstIndex(where: { $0.id == id }) {
            packets[i].state = state
        }
    }

    private func refresh() async {
        for (i, server) in servers.enumerated() {
            nodes[i].ledger = await server.ledger
            nodes[i].applied = await server.appliedCount
        }
    }
}
