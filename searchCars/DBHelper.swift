//
//  DBHelper.swift
//  searchCars
//
//  Created by Paul Murnane on 18/12/2023.
//

import Foundation
import SQLite

class DBHelper {
    static let shared = DBHelper()

    private var db: Connection?

    private let carsTable = Table("cars")
    private let id = Expression<Int>("id")
    private let registration = Expression<String>("registration")
    private let details = Expression<String>("details")

    private init() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!

            db = try Connection("\(path)/db.sqlite3")

            createTable()
        } catch {
            print("Error initializing database: \(error)")
        }
    }

    private func createTable() {
        do {
            try db?.run(carsTable.create(ifNotExists: true) { table in
                table.column(id, primaryKey: .autoincrement)
                table.column(registration, unique: true)
                table.column(details)
            })
        } catch {
            print("Error creating table: \(error)")
        }
    }

    func insertCar(registration: String, details: String) {
        do {
            try db?.run(carsTable.insert(
                self.registration <- registration,
                self.details <- details
            ))
        } catch {
            print("Error inserting car: \(error)")
        }
    }

    func getAllCars(searchQuery: String? = nil) -> [Car] {
           var cars: [Car] = []

           do {
               var query = carsTable.order(id.desc)

               if let searchQuery = searchQuery, !searchQuery.isEmpty {
                   query = query.filter(registration.like("%\(searchQuery)%"))
               }

               let result = try db?.prepare(query)

               for row in result! {
                   let car = Car(
                       id: row[id],
                       registration: row[registration],
                       details: row[details]
                   )
                   cars.append(car)
               }
           } catch {
               print("Error fetching cars: \(error)")
           }

           return cars
       }
    
    func deleteCar(_ car: Car) {
            do {
                let carToDelete = carsTable.filter(id == car.id)
                try db?.run(carToDelete.delete())
            } catch {
                print("Error deleting car: \(error)")
            }
        }
    
    func searchCarsByRegistration(registration: String) -> [Car] {
        var cars: [Car] = []

        do {
            let exactMatchQuery = try db?.prepare(carsTable.filter(self.registration == registration))

            for row in exactMatchQuery! {
                let car = Car(
                    id: row[id],
                    registration: row[self.registration],
                    details: row[details]
                )
                cars.append(car)
            }
        } catch {
            assertionFailure("Error searching cars by registration: \(error)")
        }

        return cars
    }

}
