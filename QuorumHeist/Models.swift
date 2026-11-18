import Foundation //for dates

enum NodeStatus {
    case healthy
    case crashed(since: Date)

    var isUp: Bool {
        //  switch on self; return true for healthy, false for crashed
        switch self{
        case .healthy:
            return true
        case .crashed:
            return false
        }
    }
}

nonisolated struct Account: Identifiable {
    let id: Int
    var owner: String
    var balance: Int   // whole dollars
    var version = 0 //to keep records of R and W
}

nonisolated struct Ledger {
    var accounts: [Account]

    var total: Int {
        // TODO: sum of all balances
        var count = 0
        for account in accounts {
            count += account.balance
            
        }
        return count
    }

    func balance(of accountID: Int) -> Int? {
        // TODO: that account's balance, or nil if no such account
        for account in accounts{
            if accountID == account.id{
                return account.balance
            }
            
        }
                
        return nil
    }
    mutating func apply(_ transfer: Transfer) {
        // TODO: find the index of the `from` account and the `to` account.
            // If either is missing, or `from` can't afford it, do nothing.
            // Otherwise move `amount` from one to the other.
        guard let fromIndex = accounts.firstIndex(where: { $0.id == transfer.from }) else { return }
        guard let toIndex = accounts.firstIndex(where: { $0.id == transfer.to }) else { return }
        guard accounts[fromIndex].balance >= accounts[toIndex].balance else { return }

        accounts[fromIndex].balance -= transfer.amount
        accounts[toIndex].balance += transfer.amount
    }
}

//new transfer type
nonisolated struct Transfer: Identifiable, Sendable {
    let id = UUID()
    let from: Int     // account id (1...10)
    let to: Int
    let amount: Int
}


struct ServerNode: Identifiable {
    let id: Int
    let name: String
    var ledger: Ledger
    var status: NodeStatus = .healthy
    var applied = 0 //how many servers this node has recieved
}

func makeStartingCluster() -> [ServerNode] {
    var accounts: [Account] = []
    for i in 1...10 {
        accounts.append(Account(id: i, owner: "Customer \(i)", balance: 1000))
    }

    let ledger = Ledger(accounts: accounts)

    let names = ["A", "B", "C", "D", "E"]
    var nodes: [ServerNode] = []
    for (index, name) in names.enumerated() {
        nodes.append(ServerNode(id: index, name: name, ledger: ledger))
    }
    return nodes
}


func valueSemanticsDemo() {
    var nodes = makeStartingCluster()
    nodes[0].ledger.accounts[0].balance -= 500
    print("A total:", nodes[0].ledger.total)
    print("B total:", nodes[1].ledger.total)
}
