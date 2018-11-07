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

    private var appID: String!
    private var authURI: String!
    private var clientID: String!
    private var redirectScheme: String!
    private var scope: String!
    private var tokenURI: String!


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
         *       try HMLocalDevice.shared.initialise(deviceCertificate: Base64String, devicePrivateKey: Base64String, issuerPublicKey: Base64String)
         *   }
         *   catch {
         *       // Handle the error
         *       print("Invalid initialisation parameters, please double-check the snippet: \(error)")
         *   }
         */


        <#Paste the SNIPPET here#>


        appID = "<#String#>"
        authURI = "<#String#>"
        clientID = "<#String#>"
        redirectScheme = "<#String#>"   // Insert the same scheme to Project > Info > URL Types > URL Schemes (without the ://in-app-callback part)
        scope = "<#String#>"
        tokenURI = "<#String#>"

        guard HMLocalDevice.shared.certificate != nil else {
            fatalError("\n\nYou've forgotten the LocalDevice's INITIALISATION")
        }

        guard ![appID, authURI, clientID, redirectScheme, scope, tokenURI].contains(where: { (str: String?) -> Bool in str == "<#String#>" }) else {
            fatalError("\n\nYou've forgotten to set the necessary variables!")
        }

        // Logging options that are interesting to you
        HMLocalDevice.loggingOptions = [.bluetooth, .telematics, .oauth]

        // After a tiny delay, open the OAuth URL
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            HMOAuth.shared.launchAuthFlow(appID: self.appID, authURI: self.authURI, clientID: self.clientID, redirectScheme: self.redirectScheme, scope: self.scope, tokenURI: self.tokenURI, state: "mikuonu", for: self) { authResult in
                OperationQueue.main.addOperation {
                    switch authResult {
                    case .error(let error, let state):
                        self.label.text = "DOWNLOAD ACCESS CERTS\nerror: \(error)\nstate:" + (state ?? "nil")

                    case .success(let token, let state):
                        self.label.text = "ACCESS TOKEN\nsuccess: " + token + "\nstate:" + (state ?? "nil")

                        print("TOKEN:", token, "state:", state ?? "nil")

                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
                            self.downloadAccessCertificatesAndSendTelematicsCommand(accessToken: token)
                        }
                    }
                }
            }
        }
    }
}

private extension ViewController {

    func downloadAccessCertificatesAndSendTelematicsCommand(accessToken: String) {
        button.setTitle("Downloading Access Certificates...", for: .normal)

        do {
            try HMTelematics.downloadAccessCertificate(accessToken: accessToken, completion: { (resultWithVehicleSerial: HMTelematicsRequestResult<Data>) in
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

    func sendTelematicsCommand(to vehicleSerial: Data) {
        button.setTitle("Sending Telematics command...", for: .normal)

        do {
            let command = AADoorLocks.lockUnlock(.unlocked)

            try HMTelematics.sendCommand(command, serial: vehicleSerial, completionHandler: { (result: HMTelematicsRequestResult<Data?>) in
                OperationQueue.main.addOperation {
                    switch result {
                    case .failure(let reason):
                        self.label.text = "SENT TELEMATICS COMMAND\nerror: " + reason

                    case .success(let responseData):
                        guard let data = responseData else {
                            return self.label.text = "SENT TELEMATICS COMMAND\nerror: [no data]"
                        }

                        self.label.text = "SENT TELEMATICS COMMAND\nsuccess: " + data.map { String(format: "%02X", $0) }.joined()

                        guard let response = AutoAPI.parseBinary(data) as? AADoorLocks else {
                            return self.label.text = "SENT TELEMATICS COMMAND\nerror: response is of unexpected value" + data.map { String(format: "%02X", $0) }.joined()
                        }

                        self.label.text = "SENT TELEMATICS COMMAND\nsuccess: \(String(describing: response.locks))".replacingOccurrences(of: "AutoAPI.", with: "")
                    }
                }
            })
        }
        catch {
            label.text = "SEND TELEMATICS COMMAND\nerror: \(error)"
        }
    }
}
