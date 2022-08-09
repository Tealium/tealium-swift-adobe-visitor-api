//
//  AdobeUtils.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
#if COCOAPODS
import TealiumSwift
#else
import TealiumCore
#endif

typealias NetworkResult = Result<(URLResponse, Data), Error>

extension URLSession: NetworkSession {
    func loadData(from request: URLRequest,
                         completionHandler: @escaping (NetworkResult) -> Void) {

        let task = dataTask(with: request) { data, urlResponse, error in
            TealiumQueues.backgroundSerialQueue.async {
                if let error = error {
                    completionHandler(.failure(error))
                } else {
                    guard let urlResponse = urlResponse,
                          let data = data else {
                        let error = NSError(domain: "error", code: 0, userInfo: nil)
                        completionHandler(.failure(error))
                        return
                    }
                    completionHandler(.success((urlResponse, data)))
                }
            }
        }

        task.resume()
    }

    func invalidateAndClose() {
        self.finishTasksAndInvalidate()
    }

    func reset() {
        self.reset(completionHandler: {})
    }
}

protocol NetworkSession {

    func loadData(from request: URLRequest,
                  completionHandler: @escaping (NetworkResult) -> Void)

    func invalidateAndClose()

    func reset()
}

protocol Retryable {
    var maxRetries: Int { get }
    init(queue: DispatchQueue,
         delay: TimeInterval?,
         maxRetries: Int)
    func submit(completion: @escaping () -> Void)
}

class RetryManager: Retryable {
    var queue: DispatchQueue
    var delay: TimeInterval?
    var maxRetries: Int

    required init(queue: DispatchQueue, delay: TimeInterval?, maxRetries: Int) {
        self.queue = queue
        self.delay = delay
        self.maxRetries = maxRetries
    }

    func submit(completion: @escaping () -> Void) {
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + delay, execute: completion)
        } else {
            queue.async {
                completion()
            }
        }
    }
}
