actor ReplicaServer {
    let id: Int
    let name: String
    private(set) var ledger: Ledger
    private(set) var appliedCount = 0
    private(set) var isUp = true
    
//    trasnfer//    let id = UUID()
//    let from: Int     // account id (1...10)
//    let to: Int
//    let amount: Int
//}

    init(id: Int, name: String, ledger: Ledger) {
        self.id = id
        self.name = name
        self.ledger = ledger
    }

    func read(accountID: Int) throws -> Account {
        guard isUp else { throw NetworkError.serverDown }
        guard let account = ledger.accounts.first(where: { $0.id == accountID }) else {
            throw NetworkError.unknownAccount
        }
        return account
    }

    func write(_ account: Account) throws {
        // TODO (you):
        // 1. if down → throw .serverDown
        // 2. find the index of the account with this id (else throw .unknownAccount)
        // 3. ONLY if account.version > the stored one's version:
        //      replace the stored account, appliedCount += 1
        //    (older or equal versions are ignored, because newer data wins)
        guard isUp else{ throw NetworkError.serverDown}
        guard let i = ledger.accounts.firstIndex(where: { $0.id == account.id}) else{
            throw NetworkError.unknownAccount
        }
        let currentStoredAccount = ledger.accounts[i]
        guard account.version > currentStoredAccount.version else { return }
        ledger.accounts[i] = account
        appliedCount += 1
    }
    
    func setUp(_ up: Bool) {
            isUp = up
        }
}
