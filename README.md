# Overview

This sample app for iOS uses the OAuth API of High-Mobility to have car access granted by the owner. The OAuth flow is described in detail [here](https://high-mobility.com/learn/documentation/cloud-api/oauth2/intro/#mobile-and-native-apps).

# Configuration

Before running the app, make sure to configure the following in `Manager.swift`:

1. Initialise HMKit with a valid device certiticate from the Developer Center https://developers.high-mobility.com/
2. In the Developer Center, go to the `OAuth2 Client` settings page
3. Copy and insert the Client ID, Client Secret, Auth URI, Token URI, URL Scheme and scope into the app. No worries, all of this is written on OAuth page
4. Also insert the App ID in the `Manager.swift ` file where there's a placeholder

# Run the app

Run the app on your phone and start the OAuth process. Once completed you will receive an `Access Token` that is passed into HMKit to download access certificates for the car. With this, the device has been authorised.

# Questions or Comments ?

If you have questions or if you would like to send us feedback, join our [Slack Channel](https://slack.high-mobility.com/) or email us at [support@high-mobility.com](mailto:support@high-mobility.com).
