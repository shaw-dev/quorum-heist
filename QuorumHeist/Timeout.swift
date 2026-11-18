/// Runs `operation`, but gives up after `limit`. Returns nil on timeout.
nonisolated func withTimeout<T: Sendable>(_ limit: Duration,
                                          _ operation: @escaping @Sendable () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await operation() }
        group.addTask {
            // TODO (you): sleep for `limit`, then return nil
            try? await Task.sleep(for: limit)
            return nil
            
        }
        // TODO (you):
        // 1. take whichever child finishes FIRST:   let first = await group.next()
        // 2. cancel the other one
        // 3. return it. `first` is a T?? (an optional inside an optional),
        //    so return `first ?? nil` to unwrap one layer.
        let first = await group.next()
        group.cancelAll()
        
        return first ?? nil
    }
}
