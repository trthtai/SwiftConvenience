//  MIT License
//
//  Copyright (c) 2021 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public struct Change<T> {
    public var old: T
    public var new: T
    
    private init(_ old: T, _ new: T) {
        self.old = old
        self.new = new
    }
}

extension Change where T: Equatable {
    public init?(old: T, new: T) {
        guard old != new else { return nil }
        self.init(old, new)
    }
    
    public func map<U: Equatable>(_ transform: (T) throws -> U) rethrows -> Change<U>? {
        try .init(old: transform(old), new: transform(new))
    }
}

extension Change {
    public static func unchecked(old: T, new: T) -> Self {
        .init(old, new)
    }
    
    public func mapUnchecked<U>(_ transform: (T) throws -> U) rethrows -> Change<U> {
        try .unchecked(old: transform(old), new: transform(new))
    }
}

extension Change: Hashable where T: Hashable {}
extension Change: Equatable where T: Equatable {}
extension Change: Codable where T: Codable {}

public struct Pair<First, Second> {
    public var first: First
    public var second: Second
    
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }
}

extension Pair {
    public func mapFirst<U>(_ transform: (First) throws -> U) rethrows -> Pair<U, Second> {
        try .init(transform(first), second)
    }
    
    public func mapSecond<U>(_ transform: (Second) throws -> U) rethrows -> Pair<First, U> {
        try .init(first, transform(second))
    }
}

extension Pair: Hashable where First: Hashable, Second: Hashable {}
extension Pair: Equatable where First: Equatable, Second: Equatable {}
extension Pair: Codable where First: Codable, Second: Codable {}

public struct KeyValue<Key, Value> {
    public var key: Key
    public var value: Value
    
    public init(_ key: Key, _ value: Value) {
        self.key = key
        self.value = value
    }
}

extension KeyValue {
    public func mapKey<U>(_ transform: (Key) throws -> U) rethrows -> KeyValue<U, Value> {
        try .init(transform(key), value)
    }
    
    public func mapValue<U>(_ transform: (Value) throws -> U) rethrows -> KeyValue<Key, U> {
        try .init(key, transform(value))
    }
}

extension KeyValue: Hashable where Key: Hashable, Value: Hashable {}
extension KeyValue: Equatable where Key: Equatable, Value: Equatable {}
extension KeyValue: Encodable where Key: Encodable, Value: Encodable {}
extension KeyValue: Decodable where Key: Decodable, Value: Decodable {}

/// An alternative between two elements
public enum Either<First, Second> {
    case first(First)
    case second(Second)
}

extension Either {
    public func mapFirst<U>(_ transform: (First) throws -> U) rethrows -> Either<U, Second> {
        switch self {
        case .first(let first):
            return try .first(transform(first))
        case .second(let second):
            return .second(second)
        }
    }
    
    public func mapSecond<U>(_ transform: (Second) throws -> U) rethrows -> Either<First, U> {
        switch self {
        case .first(let first):
            return .first(first)
        case .second(let second):
            return try .second(transform(second))
        }
    }
    
    public func flatMapFirst<U>(_ transform: (First) throws -> U) rethrows -> U? {
        guard case .first(let value) = self else { return nil }
        return try transform(value)
    }
    
    public func flatMapSecond<U>(_ transform: (Second) throws -> U) rethrows -> U? {
        guard case .second(let value) = self else { return nil }
        return try transform(value)
    }
}

extension Either: Hashable where First: Hashable, Second: Hashable {}
extension Either: Equatable where First: Equatable, Second: Equatable {}
extension Either: Codable where First: Codable, Second: Codable {}
