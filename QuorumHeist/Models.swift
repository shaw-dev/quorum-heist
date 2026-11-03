struct Account: Identifiable {
    let id: Int
    var owner: String
    var balance: Int   // whole dollars
}

struct Ledger {
    var accounts: [Account]

    var total: Int {
        // TODO: sum of all balances
    }

    func balance(of accountID: Int) -> Int? {
        // TODO: that account's balance, or nil if no such account
    }
}

struct ServerNode: Identifiable {
    let id: Int
    let name: String
    var ledger: Ledger
}

func makeStartingCluster() -> [ServerNode] {
    // TODO: 10 accounts × $1,000 = $10,000
    // 5 nodes named "A"..."E", each starting with the same ledger
}

func valueSemanticsDemo() {
    var nodes = makeStartingCluster()
    nodes[0].ledger.accounts[0].balance -= 500
    print("A total:", nodes[0].ledger.total)
    print("B total:", nodes[1].ledger.total)
}
