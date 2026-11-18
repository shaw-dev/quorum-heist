import Foundation
import SwiftData

@Model
final class Run {
    var date: Date
    var r: Int
    var w: Int
    var partitioned: Bool
    var committed: Int
    var transfers: Int
    var p50: Double
    var p95: Double
    var p99: Double
    var conflicts: Int

    init(r: Int, w: Int, partitioned: Bool, committed: Int, transfers: Int,
         p50: Double, p95: Double, p99: Double, conflicts: Int) {
        self.date = .now
        self.r = r
        self.w = w
        self.partitioned = partitioned
        self.committed = committed
        self.transfers = transfers
        self.p50 = p50
        self.p95 = p95
        self.p99 = p99
        self.conflicts = conflicts
    }

    var label: String { "R\(r)/W\(w)\(partitioned ? " split" : "")" }
}
