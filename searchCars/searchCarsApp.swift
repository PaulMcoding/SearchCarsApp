//
//  searchCarsApp.swift
//  searchCars
//
//  Created by Paul Murnane on 15/12/2023.
//

import SwiftUI

@main
struct searchCarsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
