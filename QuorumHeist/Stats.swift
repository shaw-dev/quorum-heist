import Foundation

/// Nearest-rank percentile: sort, then take the value p% of the way through.
func percentile(_ values: [Double], _ p: Double) -> Double {
    // TODO (you):
    // 1. if values is empty → return 0
    // 2. sort them, smallest first
    // 3. find the position p% of the way through
    // 4. return the value at that position
    
    guard !values.isEmpty else {
        return 0
    }
    
    let sorted = values.sorted()
    let index = Int((p / 100 * Double(sorted.count - 1)).rounded())
    return sorted[index]
}
