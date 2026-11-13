//
//  VIPER_SwiftUIApp.swift
//  VIPER-SwiftUI
//
//  Created by Salvador Lopez on 13/11/26.
//

import SwiftUI

@main
struct VIPER_SwiftUIApp: App {
    var body: some Scene {
        WindowGroup {
            //ContentView()
            ProductRouter.makeListProductView()
        }
    }
}
