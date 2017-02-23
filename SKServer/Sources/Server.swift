//
// Server.swift
//
// Copyright © 2016 Peter Zignego. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import Swifter

internal enum Reply {
    case json(response: Response)
    case text(body: String)
    case badRequest
}

internal protocol Request {
    var responseURL: String { get }
}

public final class Server {
    
    internal let http = HttpServer()
    //MARK: - OAuth
    internal let oauthURL = "https://slack.com/oauth/authorize"
    internal let clientID: String
    internal let clientSecret: String
    internal let state: String?
    internal let redirectURI: String?
    internal var delegate: OAuthDelegate?
    //Verification tokens
    internal var tokens = [String: String]()
    //Message action responders
    internal var responders = [String: MessageActionResponder]()

    public init(clientID: String, clientSecret: String, state: String? = nil, redirectURI: String? = nil, delegate: OAuthDelegate? = nil) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.state = state ?? "state"
        self.redirectURI = redirectURI
        self.delegate = delegate
        oauthRoute()
    }
    
    public func start(_ port: in_port_t = 8080, forceIPV4: Bool = false) {
        do {
            try http.start(port, forceIPv4: forceIPV4)
        } catch let error as NSError {
            print("Server failed to start with error: \(error)")
        }
    }
    
    public func stop() {
        http.stop()
    }
    
    internal func request(_ request:Request, reply: Reply) -> HttpResponse {
        switch reply {
        case .text(let body):
            return .ok(.text(body))
        case .json(let response):
            return .ok(.json(response.json as AnyObject))
        case .badRequest:
            return .badRequest(.text("Bad request."))
        }
    }
    
    internal func requestQueryItems(_ body: [UInt8]) -> [URLQueryItem]? {
        guard let string = String(data: Data(bytes: UnsafePointer<UInt8>(body), count: body.count), encoding: String.Encoding.utf8) else {
            return nil
        }
        let components = URLComponents(string: string)
        return components?.queryItems
    }
    
    internal func jsonFromRequest(_ string: String) -> [String: Any]? {
        guard let data = string.data(using: String.Encoding.utf8) else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? nil
    }
}