# Overview

This sample app for iOS uses the OAuth API of High-Mobility to have car access granted by the owner. The OAuth flow is described in detail on https://developers.high-mobility.com/resources/documentation/cloud-api/oauth2/intro

# Configuration

Before running the app, make sure to configure the following in `ViewController.swift`:

1. Initialise HMKit with a valid device certiticate from the Developer Center https://developers.high-mobility.com/
2. In the Developer Center, go to the `OAuth2 Client` settings page
3. Copy and insert the Client ID, Client Secret, Auth URI, Token URI, URL Scheme and scope into the app. No worries, all of this is written on OAuth page
4. Also insert the App ID in the `ViewController.swift` file where there's a placeholder
5. Set the scopes for which you ask permissions - the full list is here https://developers.high-mobility.com/resources/documentation/auto-api/api-structure/permissions

# Run the app

Run the app on your phone and start the OAuth process. Once completed you will receive an `Access Token` that is passed into HMKit to download access certificates for the car. With this, the device has been authorised.
