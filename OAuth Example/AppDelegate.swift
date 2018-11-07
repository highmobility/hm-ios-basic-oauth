//
//  AppDelegate.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import HMKit
import UIKit


@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return HMOAuth.shared.handleCallback(with: url)
    }
}
