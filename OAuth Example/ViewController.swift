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


    // MARK: IBActions

    @IBAction func buttonTapped(_ sender: UIButton) {
        let authURI = "https://developers.h-m.space/hm_cloud/o/58e057cb-819d-42bf-b2e4-7ed9d0fca77b/oauth"
        let clientID = "2cd61aa3-0d3a-4490-a836-1d53a3b95983"
        let redirectURI = "com.hm.dev.1503672371-xuub2pgnna8k://in-app-callback"
        let scope = "door-locks.read,door-locks.write"
        let appID = "2D26B927CBC4BC299807EC8F"

        guard let url = OAuthManager.oauthURL(authURI: authURI, clientID: clientID, redirectURI: redirectURI, scope: scope, appID: appID) else {
            return
        }

        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }


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

         Before using the HMKit, you must initialise the LocalDevice with a snippet from the Developer Center:
         - go to https://developers.high-mobility.com
         - LOGIN
         - choose DEVELOP (in top-left, the (2nd) button with a spanner)
         - choose APPLICATIONS (in the left)
         - look for SANDBOX app
         - click on the "Device Certificates" on the app
         - choose the SANDBOX DEVICE
         - copy the whole snippet
         - paste it below this comment box
         - you made it!

         Bonus steps after completing the above:
         - relax
         - celebrate
         - explore the APIs


         An example of a snippet copied from the Developer Center (do not use, will obviously not work):

         do {
            try LocalDevice.sharedDevice.initialise(deviceCertificate: Base64String,
                                                    devicePrivateKey: Base64String,
                                                    issuerPublicKey: Base64String)
         }
         catch {
            // Handle the error
            print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         }

         */

        // PASTE THE SNIPPET HERE

        guard LocalDevice.shared.certificate != nil else {
            fatalError("You've forgotten the INITIALISATION")
        }

        // Logging options that are interesting to you
        LocalDevice.loggingOptions = [.bluetooth, .telematics]
    }
}

fileprivate extension ViewController {

    func downloadAccessCertificatesAndSendTelematicsCommand(accessToken: String) {
        button.setTitle("Downloading Access Certificates...", for: .normal)

        do {
            try Telematics.downloadAccessCertificate(accessToken: accessToken, completion: { (resultWithVehicleSerial: Telematics.TelematicsRequestResult<Data>) in
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
        let tokenURI = "https://developers.h-m.space/hm_cloud/api/v1/58e057cb-819d-42bf-b2e4-7ed9d0fca77b/oauth/access_tokens"
        let redirectURI = "com.hm.dev.1503672371-xuub2pgnna8k://in-app-callback"
        let clientID = "2cd61aa3-0d3a-4490-a836-1d53a3b95983"

        button.setTitle("Getting Access Token...", for: .normal)

        OAuthManager.requestAccessToken(tokenURI: tokenURI, redirectURI: redirectURI, clientID: clientID, code: code) { (result: OAuthManager.AccessTokenResult) in
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
            typealias Command = AutoAPI.DoorLocksCommand

            let command = Command.lockDoorsBytes(.unlock)

            try Telematics.sendCommand(command, vehicleSerial: vehicleSerial, completionHandler: { (result: Telematics.TelematicsRequestResult<Data?>) in
                OperationQueue.main.addOperation {
                    switch result {
                    case .failure(let reason):
                        self.label.text = "SENT TELEMATICS COMMAND\nerror: " + reason

                    case .success(let responseData):
                        guard let data = responseData else {
                            return self.label.text = "SENT TELEMATICS COMMAND\nerror: [no data]"
                        }

                        self.label.text = "SENT TELEMATICS COMMAND\nsuccess: " + data.map { String(format: "%02X", $0) }.joined()

                        guard let response = AutoAPI.parseIncomingCommand(data)?.value as? Command.Response else {
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
