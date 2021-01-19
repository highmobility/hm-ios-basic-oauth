//
//  ContentView.swift
//  OAuth Example
//
//  Created by Mikk Rätsep on 04.02.20.
//  Copyright © 2020 High-Mobility GmbH. All rights reserved.
//

import SwiftUI


struct ContentView: View {

    @EnvironmentObject var manager: Manager

    let oauthControllerWrapper: ViewControllerWrapper


    var body: some View {
        ZStack {
            oauthControllerWrapper

            Text(manager.text)
                .font(.footnote)
                .padding()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView(oauthControllerWrapper: ViewControllerWrapper())
    }
}
