//
//  CarModel.swift
//  searchCars
//
//  Created by Paul Murnane on 18/12/2023.
//

import Foundation

struct Car: Identifiable {
    var id: Int
    var registration: String
    var details: String
    
    func share() -> String {
            return "Registration: \(registration)\nDetails: \(details)"
        }
}
