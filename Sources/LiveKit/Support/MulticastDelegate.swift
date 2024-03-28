/*
 * Copyright 2024 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

// Workaround for Swift-ObjC limitation around generics.
public protocol MulticastDelegateProtocol {
    associatedtype Delegate
    func add(delegate: Delegate)
    func remove(delegate: Delegate)
    func removeAllDelegates()
}

/// A class that allows to have multiple delegates instead of one.
///
/// Uses `NSHashTable` internally to maintain a set of weak delegates.
///
/// > Note: `NSHashTable` may not immediately deinit the un-referenced object, due to Apple's implementation, therefore `.count` is unreliable.
public class MulticastDelegate<T>: NSObject, Loggable {
    private struct State {
        var delegates = NSHashTable<AnyObject>.weakObjects()
    }

    public let label: String
    private let _state = StateSync(State())

    init(label: String) {
        self.label = label
    }

    public var allDelegates: [T] {
        _state.read { $0.delegates.allObjects.compactMap { $0 as? T } }
    }

    /// Add a single delegate.
    public func add(delegate: T) {
        guard let delegate = delegate as AnyObject? else {
            log("MulticastDelegate: delegate is not an AnyObject", .error)
            return
        }

        _state.mutate {
            $0.delegates.add(delegate)
        }
    }

    /// Remove a single delegate.
    ///
    /// In most cases this is not required to be called explicitly since all delegates are weak.
    public func remove(delegate: T) {
        guard let delegate = delegate as AnyObject? else {
            log("MulticastDelegate: delegate is not an AnyObject", .error)
            return
        }

        _state.mutate {
            $0.delegates.remove(delegate)
        }
    }

    /// Remove all delegates.
    public func removeAllDelegates() {
        _state.mutate {
            $0.delegates.removeAllObjects()
        }
    }

    func notifyDetached(_ fnc: @escaping (T) -> Void) {
        Task.detached {
            await self.notifyAsync(fnc)
        }
    }

    func notifyAsync(_ fnc: @escaping (T) -> Void) async {
        let delegates = _state.read { $0.delegates.allObjects.compactMap { $0 as? T } }
        await withTaskGroup(of: Void.self) { group in
            for delegate in delegates {
                group.addTask {
                    fnc(delegate)
                }
            }
            await group.waitForAll()
        }
    }
}
