//
//  Dispatchable.swift
//  Dispatchable
//
//  Created by wei on 2018/11/7.
//  Copyright © 2018 wei All rights reserved.
//

import Foundation

/// 1 to many observers
public protocol DispatchPool {
    /// support protocol, must be NSObjectProtocol
    associatedtype Observer: NSObjectProtocol

    /// manage Observer
    /// - Parameter observer: observer
    func add(observer: Observer)
    func del(observer: Observer)

    /// dispatch a selector with objects to observers
    /// - Parameters:
    ///   - selector: selector to dispatch
    ///   - object1: first object
    ///   - object2: second object
    func dispatch(selector: Selector, object1: Any?, object2: Any?)
}

open class Dispatcher<P: NSObjectProtocol>: DispatchPool {
    // lock
    fileprivate let mutex = NSLock()

    // 消息回调处理
    private let observers = WeakSet<P>()

    deinit {
        observers.removeAll()
    }

    open func add(observer: P) {
        mutex.lock()
        defer { mutex.unlock() }
        self.observers.add(observer)
    }

    open func del(observer: P) {
        mutex.lock()
        defer { mutex.unlock() }
        self.observers.remove(observer)
    }

    open func dispatch(selector: Selector, object1: Any?, object2: Any?) {
        let perform: ((Observer) -> Void) = { observer in
            guard observer.responds(to: selector) else {
                return
            }
            if let object2 = object2, let object1 = object1 {
                observer.perform(selector, with: object1, with: object2)
            } else if let object1 = object1 {
                observer.perform(selector, with: object1)
            } else {
                observer.perform(selector)
            }
        }

        let observers = self.observers.allObjects
        let work = {
            observers.forEach(perform)
        }
        // always in main queue
        DispatchQueue.dispatchOnMain(work)
    }
}

public protocol Dispatchable: DispatchPool {
    associatedtype Ablity: NSObjectProtocol

    var dispatcher: Dispatcher<Ablity> { get }
}

extension Dispatchable {
    public func add(observer: Self.Ablity) {
        dispatcher.add(observer: observer)
    }

    public func del(observer: Self.Ablity) {
        dispatcher.del(observer: observer)
    }

    public func dispatch(selector: Selector, object1: Any? = nil, object2: Any? = nil) {
        dispatcher.dispatch(selector: selector, object1: object1, object2: object2)
    }
}
