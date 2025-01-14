//  MIT License
//
//  Copyright (c) 2022 Alkenso (Vladimir Vashurkin)
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

/// Executes synchronously the asynchronous method with completion handler.
/// - Note: While this is not the best practice ever,
///         real-world tasks time to time require the exact approach.
public struct SynchronousExecutor {
    public var name: String?
    public var timeout: TimeInterval?
    
    public init(_ name: String? = nil, timeout: TimeInterval?) {
        self.name = name
        self.timeout = timeout
    }
    
    public func callAsFunction<T>(_ action: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        @Atomic var result: Result<T, Error>!
        let group = DispatchGroup()
        group.enter()
        action {
            result = $0
            group.leave()
        }
        
        if let timeout = timeout {
            guard group.wait(timeout: .now() + timeout) == .success else {
                throw CommonError.timedOut(what: name ?? "Operation")
            }
        } else {
            group.wait()
        }
        
        return try result.get()
    }
}

extension SynchronousExecutor {
    public func callAsFunction(_ action: @escaping (@escaping (Error?) -> Void) -> Void) throws {
        try callAsFunction { (reply: @escaping (Result<(), Error>) -> Void) in
            action {
                if let error = $0 {
                    reply(.failure(error))
                } else {
                    reply(.success(()))
                }
            }
        }
    }
    
    public func callAsFunction<T>(_ action: @escaping (@escaping (T?) -> Void) -> Void) throws -> T {
        try callAsFunction { (reply: @escaping (Result<T, Error>) -> Void) in
            action { optionalValue in
                reply(Result { try optionalValue.get() })
            }
        }
    }
}
