//
//  BoundedCache.swift
//  Theme
//

import Foundation

/// Fixed-capacity least-recently-used cache.
struct BoundedCache<Key: Hashable, Value> {
    private struct Entry {
        var value: Value
        var lastUsed: UInt64
    }

    let capacity: Int
    private var storage = [Key: Entry]()
    private var tick: UInt64 = 0

    init(capacity: Int) {
        precondition(capacity > 0, "capacity must be positive")
        self.capacity = capacity
    }

    var count: Int { storage.count }

    mutating func value(for key: Key) -> Value? {
        guard var entry = storage[key] else { return nil }
        tick &+= 1
        entry.lastUsed = tick
        storage[key] = entry
        return entry.value
    }

    mutating func insert(_ value: Value, for key: Key) {
        tick &+= 1
        storage[key] = Entry(value: value, lastUsed: tick)
        if storage.count > capacity, let oldest = storage.min(by: { $0.value.lastUsed < $1.value.lastUsed })?.key {
            storage.removeValue(forKey: oldest)
        }
    }

    mutating func removeAll() {
        storage.removeAll()
    }

    mutating func removeAll(where shouldRemove: (Key) -> Bool) {
        storage = storage.filter { !shouldRemove($0.key) }
    }
}
