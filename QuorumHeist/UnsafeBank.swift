import Foundation

// `nonisolated` = step OFF the main actor so multiple threads can run this.
// `@unchecked Sendable` = we're LYING to the compiler: "trust me, it's thread-safe."
// It isn't. That's the point.
nonisolated final class UnsafeBank: @unchecked Sendable {
    var balances: [Int] = Array(repeating: 1000, count: 10)

    var total: Int { balances.reduce(0, +) }

    func transfer(from: Int, to: Int, amount: Int) {
        // TODO (you): if `from` has at least `amount`,
        // subtract it from balances[from] and add it to balances[to]
        
        if balances[from] >= amount{
            (balances[from] -= amount)
            balances[to] += amount
        }
    }
}

// Fires `transfers` transfers at the bank, all running concurrently.
nonisolated func hammer(_ bank: UnsafeBank, transfers: Int) async {
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<transfers {
            group.addTask {
                let from = Int.random(in: 0..<10)
                let to = Int.random(in: 0..<10)
                bank.transfer(from: from, to: to, amount: Int.random(in: 1...50))
            }
        }
    }
}



actor SafeBank {
    var balances: [Int] = Array(repeating: 1000, count: 10)

    var total: Int { balances.reduce(0, +) }

    func transfer(from: Int, to: Int, amount: Int) {
        // TODO (you): if `from` has at least `amount`,
        // subtract it from balances[from] and add it to balances[to]
        
        if balances[from] >= amount{
            (balances[from] -= amount)
            balances[to] += amount
        }
    }
}


// Fires `transfers` transfers at the bank, all running concurrently.
nonisolated func hammerSafe(_ bank: SafeBank, transfers: Int) async {
    await withTaskGroup(of: Void.self) { group in
        for _ in 0..<transfers {
            group.addTask {
                let from = Int.random(in: 0..<10)
                let to = Int.random(in: 0..<10)
                await bank.transfer(from: from, to: to, amount: Int.random(in: 1...50))
            }
        }
    }
}
