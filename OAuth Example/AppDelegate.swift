//
//  AppDelegate.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import UIKit


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    fileprivate var viewController: ViewController!


    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        guard let viewController = window?.rootViewController as? ViewController else {
            return false
        }

        self.viewController = viewController

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let parsedResponse = OAuthManager.parseRedirectURL(url)

        switch parsedResponse {
        case .unknown:
            print("Can't open this app with URL: \(url.absoluteString)")

            return false

        default:
            viewController.oauthResponseReceived(parsedResponse)

            return true
        }
    }
}
