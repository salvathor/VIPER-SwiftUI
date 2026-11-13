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
            // Punto de entrada VIPER: la App no crea la vista directamente,
            // le pide al Router el módulo ya ensamblado (View + Presenter + Interactor).
            ProductRouter.makeListProductView()
        }
    }
}
