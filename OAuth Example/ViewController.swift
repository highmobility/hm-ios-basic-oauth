//
//  ViewController.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 25/08/2017.
//  Copyright © 2017 High-Mobility GmbH. All rights reserved.
//

import AutoAPI
import HMKit
import UIKit


class ViewController: UIViewController {

    @IBOutlet var button: UIButton!
    @IBOutlet var label: UILabel!

    fileprivate var appID: String!
    fileprivate var authURI: String!
    fileprivate var clientID: String!
    fileprivate var redirectScheme: String!
    fileprivate var scope: String!
    fileprivate var tokenURI: String!


    // MARK: Methods

    func oauthResponseReceived(_ response: OAuthManager.RedirectResult) {
        var text: String

        switch response {
        case .error(reason: let reason, state: let state):
            text = "ACCESS TOKEN CODE\nerror: " + reason

            if let state = state {
                text += "\n" + state
            }

        case .successful(accessTokenCode: let tokenCode, state: let state):
            text = "ACCESS TOKEN CODE\nsuccess: " + tokenCode

            if let state = state {
                text += "\n" + state
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                self.executeAccessTokenRequest(code: tokenCode)
            }

        case .unknown:
            text = "ACCESS TOKEN\nIMPOSSIBLE..."
        }

        button.isEnabled = false
        label.text = text
    }


    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         * Before using HMKit, you'll have to initialise the LocalDevice singleton
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
         *       try LocalDevice.shared.initialise(deviceCertificate: Base64String, devicePrivateKey: Base64String, issuerPublicKey: Base64String)
         *   }
         *   catch {
         *       // Handle the error
         *       print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         *   }
         */


        <#Paste the SNIPPET here#>


        guard LocalDevice.shared.certificate != nil else {
            fatalError("\n\nYou've forgotten the LocalDevice's INITIALISATION")
        }


        appID = "<#String#>"
        authURI = "<#String#>"
        clientID = "<#String#>"
        redirectScheme = "<#String#>"
        scope = "<#String#>"
        tokenURI = "<#String#>"


        guard ![appID, authURI, clientID, redirectScheme, scope, tokenURI].contains(where: { (str: String?) -> Bool in (str == nil) || (str == "<#String#>") }) else {
            fatalError("\n\nYou've forgotten to set the necessary variables!")
        }



        // Logging options that are interesting to you
        LocalDevice.loggingOptions = [.bluetooth, .telematics]

        // After a tiny delay, open the OAuth URL
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            guard let url = OAuthManager.oauthURL(authURI: self.authURI, clientID: self.clientID, redirectScheme: self.redirectScheme, scope: self.scope, appID: self.appID) else {
                return
            }

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

fileprivate extension ViewController {

    func downloadAccessCertificatesAndSendTelematicsCommand(accessToken: String) {
        button.setTitle("Downloading Access Certificates...", for: .normal)

        do {
            try Telematics.downloadAccessCertificate(accessToken: accessToken, completion: { (resultWithVehicleSerial: TelematicsRequestResult<Data>) in
                OperationQueue.main.addOperation {
                    switch resultWithVehicleSerial {
                    case .failure(let reason):
                        self.label.text = "DOWLOAD ACCESS CERTS\nerror: " + reason

                    case .success(let vehicleSerial):
                        self.label.text = "DOWLOAD ACCESS CERTS\nsuccess: " + vehicleSerial.map { String(format: "%02X", $0) }.joined()

                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            self.sendTelematicsCommand(to: vehicleSerial)
                        }
                    }
                }
            })
        }
        catch {
            label.text = "DOWLOAD ACCESS CERTS\nerror: \(error)"
        }
    }

    func executeAccessTokenRequest(code: String) {
        button.setTitle("Getting Access Token...", for: .normal)

        OAuthManager.requestAccessToken(tokenURI: tokenURI, redirectScheme: redirectScheme, clientID: clientID, code: code) { (result: OAuthManager.AccessTokenResult) in
            OperationQueue.main.addOperation {
                switch result {
                case .error(let reason):
                    self.label.text = "ACCESS TOKEN\nerror: " + reason

                case .successful(accessToken: let token):
                    self.label.text = "ACCESS TOKEN\nsuccess: " + token

                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                        self.downloadAccessCertificatesAndSendTelematicsCommand(accessToken: token)
                    }
                }
            }
        }
    }

    func sendTelematicsCommand(to vehicleSerial: Data) {
        button.setTitle("Sending Telematics command...", for: .normal)

        do {
            let command = DoorLocks.lockUnlock(.unlock)

            try Telematics.sendCommand(command, serial: vehicleSerial, completionHandler: { (result: TelematicsRequestResult<Data?>) in
                OperationQueue.main.addOperation {
                    switch result {
                    case .failure(let reason):
                        self.label.text = "SENT TELEMATICS COMMAND\nerror: " + reason

                    case .success(let responseData):
                        guard let data = responseData else {
                            return self.label.text = "SENT TELEMATICS COMMAND\nerror: [no data]"
                        }

                        self.label.text = "SENT TELEMATICS COMMAND\nsuccess: " + data.map { String(format: "%02X", $0) }.joined()

                        guard let response = AutoAPI.parseBinary(data) as? DoorLocks else {
                            return self.label.text = "SENT TELEMATICS COMMAND\nerror: response is of unexpected value" + data.map { String(format: "%02X", $0) }.joined()
                        }

                        self.label.text = "SENT TELEMATICS COMMAND\nsuccess: \(response.doors)".replacingOccurrences(of: "AutoAPI.", with: "")
                    }
                }
            })
        }
        catch {
            label.text = "SEND TELEMATICS COMMAND\nerror: \(error)"
        }
    }
}
