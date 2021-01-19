//
//  ViewController.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import AutoAPI
import Combine
import HMKit
import SwiftUI
import UIKit


class Manager: ObservableObject {

    @Published private(set) var text: String = "launching OAuth..."

    private let downloadCertPub: AnyPublisher<[UInt8], HMTelematicsError>
    private let oauthFlowPub: AnyPublisher<HMOAuthSuccess, HMOAuthFailure>
    private let sendCommandPub: AnyPublisher<[AALock], HMTelematicsError>

    private var sinks: [AnyCancellable] = []


    // MARK: Init

    init(oauthControllerWrapper: ViewControllerWrapper) {
        /*
         * Before using HMKit, you'll have to initialise the HMLocalDevice singleton
         * with a snippet from the Platform Workspace:
         *
         *   1. Sign in to the workspace
         *   2. Go to the LEARN section and choose iOS
         *   3. Follow the Getting Started instructions
         *
         * By the end of the tutorial you will have a snippet for initialisation,
         * that looks something like this:
         *
         *   do {
         *       try HMLocalDevice.shared.initialise(certificate: Base64String, devicePrivateKey: Base64String, issuerPublicKey: Base64String)
         *   }
         *   catch {
         *       // Handle the error
         *       print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         *   }
         */


        <#Paste the SNIPPET here#>


        // Logging options that are interesting to you
        HMLocalDevice.shared.loggingOptions = [.telematics, .oauth, .urlRequests]

        /*
         * Before using OAuth, you'll need to insert the OAuth required values.
         *
         *   1. Sign in to the workspace
         *   2. Click on your icon in the top-right corner and choose MY SETTINGS
         *   3. Go to OAUTH CLIENT
         *   4. Copy the matching values here ("URL-scheme" == "redirectScheme")
         *   5. Go to your app in the workspace and copy it's identifier
         *
         *
         *  Finally insert the REDIRECT_SCHEME (without the ://in-app-callback part) to:
         *   a. Project > Info > URL Types > URL Schemes
         *    or
         *   b. Info.plist > URL types > Item 0 > URL Schemes > Item 0
         */
        let requiredValues = HMOAuthRequiredValues(appID: <#String#>,
                                                   authURI: <#String#>,
                                                   clientID: <#String#>,
                                                   redirectScheme: <#String#>,
                                                   tokenURI: <#String#>)


        // After a tiny delay, open the OAuth URL
        oauthFlowPub = Just<Void>(())
            .setFailureType(to: HMOAuthFailure.self)
            .delay(for: 1.0, scheduler: OperationQueue.main)
            .flatMap { _ in
                Future<HMOAuthSuccess, HMOAuthFailure> { promise in
                    HMOAuth.shared.launchAuthFlow(requiredValues: requiredValues, optionalValues: nil, for: oauthControllerWrapper.controller, handler: promise)
                }
            }
            .share()
            .eraseToAnyPublisher()

        // Download Access Certificate after OAuth is done
        downloadCertPub = oauthFlowPub
            .delay(for: 1.0, scheduler: OperationQueue())
            .mapError { oauthFailure -> HMTelematicsError in
                .misc(oauthFailure)
            }
            .flatMap { oauthSuccess in
                Future<[UInt8], HMTelematicsError> { promise in
                    do {
                        try HMTelematics.downloadAccessCertificate(accessToken: oauthSuccess.accessToken, completionWithSerial: promise)
                    }
                    catch {
                        promise(.failure(.misc(error)))
                    }
                }
            }
            .share()
            .eraseToAnyPublisher()

        // Send "lock doors" command (and parse the response) after receiving the AC
        sendCommandPub = downloadCertPub
            .delay(for: 1.0, scheduler: OperationQueue())
            .flatMap { serial in
                Future<HMTelematicsRequestSuccess, HMTelematicsError> { promise in
                    do {
                        let command = AADoors.lockUnlockDoors(locksState: .unlocked)

                        try HMTelematics.sendCommand(command, serial: serial, completionWithResponse: promise)
                    }
                    catch {
                        promise(.failure(.misc(error)))
                    }
                }
            }
            .tryMap { telemSuccess -> [AALock] in
                guard let doors = try AAAutoAPI.parseBytes(telemSuccess.response) as? AADoors,
                    let locks = doors.locks?.compactMap({ $0.value }) else {
                        throw HMTelematicsError.invalidData
                }

                return locks
            }
            .mapError { error -> HMTelematicsError in
                guard let telemError = error as? HMTelematicsError else {
                    return .misc(error)
                }

                return telemError
            }
            .share()
            .eraseToAnyPublisher()

        // Create some sinks
        createTextSink().store(in: &sinks)
    }
}

private extension Manager {

    var downloadCertTextPub: AnyPublisher<String, Never> {
        downloadCertPub
            .map { serial in
                """
                DOWNLOADED ACCESS CERTS
                 serial: \(serial.hex)
                """
            }
            .catch { telemError in
                Just("""
                    DOWNLOAD ACCESS CERTS
                     error: \(telemError)
                    """)
            }
            .eraseToAnyPublisher()
    }

    var oauthFlowTextPub: AnyPublisher<String, Never> {
        oauthFlowPub
            .map { oauthSuccess in
                """
                ACCESS TOKEN
                 success: \(oauthSuccess.accessToken.prefix(20))...
                """
            }
            .catch { oauthFailure in
                Just("""
                    ACCESS TOKEN
                     error: \(oauthFailure.reason)
                     state: \(oauthFailure.state ?? "nil")
                    """)
            }
            .eraseToAnyPublisher()
    }

    var sendCommandTextPub: AnyPublisher<String, Never> {
        sendCommandPub
            .map { locks -> String in
                let str = locks.map {
                    "   \($0.location): \($0.lockState)"
                }.joined(separator: "\n")

                return """
                SENT & RECEIVED TELEM. COMMAND
                 locks:
                \(str)
                """
            }
            .catch { telemError in
                Just("""
                    SENT TELEM. COMMAND
                     error: \(telemError)
                    """)
            }
            .eraseToAnyPublisher()
    }


    func createTextSink() -> AnyCancellable {
        oauthFlowTextPub
            .merge(with: downloadCertTextPub, sendCommandTextPub)
            .receive(on: OperationQueue.main)
            .sink {
                self.text += "\n\n\n"
                self.text += $0
            }
    }
}
