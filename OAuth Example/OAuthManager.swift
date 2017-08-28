//
//  OAuthManager.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import Foundation


struct OAuthManager {

    enum RedirectResult {
        case successful(accessTokenCode: String, state: String?)
        case error(reason: String, state: String?)
        case unknown
    }

    enum AccessTokenResult {
        case successful(accessToken: String)
        case error(String)
    }

    typealias AccessTokenCompletionBlock = (AccessTokenResult) -> Void


    static func oauthURL(authURI: String, clientID: String, redirectURI: String, scope: String, appID: String, state: String? = nil, validity: (start: Date, end: Date)? = nil) -> URL? {
        var completeURI: String = authURI

        completeURI += "?client_id=" + clientID
        completeURI += "&redirect_uri=" + redirectURI
        completeURI += "&scope=" + scope
        completeURI += "&app_id=" + appID

        if let state = state {
            completeURI += "&state=" + state
        }

        if let validity = validity {
            let dateFormatter = ISO8601DateFormatter()

            completeURI += "&validity_start_date=" + dateFormatter.string(from: validity.start)
            completeURI += "&validity_end_date=" + dateFormatter.string(from: validity.end)
        }

        guard let url = URL(string: completeURI) else {
            return nil
        }

        return url
    }

    static func parseRedirectURL(_ redirectURL: URL) -> RedirectResult {
        guard let queryItems = URLComponents(url: redirectURL, resolvingAgainstBaseURL: false)?.queryItems else {
            return .unknown
        }

        let stateValue = queryItems.first(where: { $0.name == "state" })?.value

        if let errorValue = queryItems.first(where: { $0.name == "error" })?.value {
            return .error(reason: errorValue, state: stateValue)
        }
        else if let codeValue = queryItems.first(where: { $0.name == "code" })?.value {
            return .successful(accessTokenCode: codeValue, state: stateValue)
        }
        else {
            return .unknown
        }
    }

    static func requestAccessToken(tokenURI: String, redirectURI: String, clientID: String, code: String, completion: @escaping AccessTokenCompletionBlock) {
        var completeURI: String = tokenURI

        completeURI += "?client_id=" + clientID
        completeURI += "&code=" + code
        completeURI += "&redirect_uri=" + redirectURI

        guard let url = URL(string: completeURI) else {
            return completion(.error("Failed to combine URL from: \(completeURI)"))
        }

        let request = URLRequest(url: url, httpMethod: "POST")

        URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard error == nil else {
                return completion(.error("Request returned an error: \(error!)"))
            }

            guard let data = data else {
                return completion(.error("Missing data, error: \(String(describing: error)), response: \(String(describing: response))"))
            }

            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                let hex = data.map { String(format: "%02X", $0) }.joined()

                return completion(.error("Failed to create JSON object from: \(hex)"))
            }

            guard let accessToken = json?["access_token"] as? String else {
                return completion(.error("Failed to extract Access Token from json: \(String(describing: json))"))
            }

            completion(.successful(accessToken: accessToken))
        }.resume()
    }
}

fileprivate extension URLRequest {

    init(url: URL, httpMethod: String) {
        self.init(url: url)

        self.httpMethod = httpMethod
    }
}
