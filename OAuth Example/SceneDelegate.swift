//
//  SceneDelegate.swift
//  hm-ios-sixt-looper
//
//  Created by Mikk Rätsep on 23.01.20.
//  Copyright © 2020 High Mobility GmbH. All rights reserved.
//

import HMKit
import SwiftUI
import UIKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        // Create the SwiftUI view that provides the window contents.
        let wrapper = ViewControllerWrapper()
        let manager = Manager(oauthControllerWrapper: wrapper)
        let contentView = ContentView(oauthControllerWrapper: wrapper).environmentObject(manager)

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)

            window?.rootViewController = UIHostingController(rootView: contentView)
            window?.makeKeyAndVisible()
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        HMOAuth.shared.handleCallback(with: url)
    }
}





struct ViewControllerWrapper: UIViewControllerRepresentable {

    let controller = UIViewController()


    // MARK: UIViewControllerRepresentable

    typealias UIViewControllerType = UIViewController


    func makeUIViewController(context: UIViewControllerRepresentableContext<ViewControllerWrapper>) -> UIViewController {
        controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<ViewControllerWrapper>) { }
}
