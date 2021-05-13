//
//  AdobeUtils.swift
//  TealiumAdobeVisitorAPI
//
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

typealias NetworkResult = Result<(URLResponse, Data), Error>

extension URLSession: NetworkSession {
    func loadData(from request: URLRequest,
                         completionHandler: @escaping (NetworkResult) -> Void) {

        let task = dataTask(with: request) { data, urlResponse, error in
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
    init(queue: DispatchQueue,
         delay: TimeInterval?)
    func submit(completion: @escaping () -> Void)
}

class RetryManager: Retryable {
    var queue: DispatchQueue
    var delay: TimeInterval?

    required init(queue: DispatchQueue, delay: TimeInterval?) {
        self.queue = queue
        self.delay = delay
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
