import Foundation

nonisolated enum NetworkError: Error {
    case dropped
    case serverDown
    case unknownAccount
}

protocol Network: Sendable {
    func send<Reply: Sendable>(
        to server: ReplicaServer,
        _ operation: @Sendable (ReplicaServer) async throws -> Reply
    ) async throws -> Reply
}

nonisolated struct SimulatedNetwork: Network {
    var delay: ClosedRange<Int> = 20...200
    var dropRate: Double = 0.1 //10% dropped
    var unreachable: Set<Int> = []    // server ids this client can't reach
    
    
    func send<Reply: Sendable>(
        to server: ReplicaServer,
        _ operation: @Sendable (ReplicaServer) async throws -> Reply
    ) async throws -> Reply {
        
        // TODO (you): if `unreachable` contains server.id, the message vanishes into the void:
        // sleep for a very long time (try `.seconds(3600)`), then throw NetworkError.dropped.
        // Nobody will actually wait an hour; the caller's timeout gives up first.
        
        if unreachable.contains(server.id){
            try await Task.sleep(for: .seconds(3600))
            throw NetworkError.dropped
        }
        // TODO (you): same 3 steps as your old `deliver`:
        // sleep, maybe throw .dropped, then:  return try await operation(server)
        // TODO (you), three lines:
                // 1. sleep for a random number of milliseconds within `delay`
                // 2. with probability `dropRate`, throw NetworkError.dropped
                // 3. otherwise: try await server.apply(transfer)
        try await Task.sleep(for: .milliseconds(Int.random(in: delay)))
        if Double.random(in: 0..<1) < dropRate {
                    throw NetworkError.dropped
                }
                
                // 3. Otherwise: execute the custom action and return its value
        return try await operation(server)
    }
}
