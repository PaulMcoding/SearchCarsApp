//
//  CarService.swift
//  searchCars
//
//  Created by Paul Murnane oxn 15/12/2023.
//

import Foundation
import SwiftSoup

protocol CarService {
    func getCarDetails(registration: String, completion: @escaping (Result<String, Error>) -> Void)
}

class CarServiceImpl: CarService {
    private let motorcheckURL = URL(string: "https://www.motorcheck.ie/free-car-check/?vrm=222D4&campaign=1")!
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration)
    }()

    func getCarDetails(registration: String, completion: @escaping (Result<String, Error>) -> Void) {
        var motorcheckComponents = URLComponents(url: motorcheckURL, resolvingAgainstBaseURL: true)!
        motorcheckComponents.queryItems = [URLQueryItem(name: "vrm", value: registration)]

        guard let motorcheckFinalURL = motorcheckComponents.url else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }

        var motorcheckRequest = URLRequest(url: motorcheckFinalURL)
        motorcheckRequest.httpMethod = "GET"

        let motorcheckTask = urlSession.dataTask(with: motorcheckRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "No data received from Motorcheck", code: 0, userInfo: nil)))
                return
            }

            do {
                let motorcheckResultString = try self.parseMotorcheckHTML(data: data)
                completion(.success(motorcheckResultString))
            } catch {
                completion(.failure(error))
            }
        }

        motorcheckTask.resume()
    }

    func searchCarsByRegistration(registration: String, completion: @escaping (Result<String, Error>) -> Void) {
        let localCars = DBHelper.shared.searchCarsByRegistration(registration: registration)

        if !localCars.isEmpty {
            completion(.success("Details found locally"))
        } else {
            getCarDetails(registration: registration) { result in
                switch result {
                case .success(let details):
                    DBHelper.shared.insertCar(registration: registration, details: details)
                    completion(.success(details))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func parseMotorcheckHTML(data: Data) throws -> String {
        let motorcheckResultString = String(data: data, encoding: .utf8) ?? ""

        do {
            let document = try SwiftSoup.parse(motorcheckResultString)

            // Extracting title
            if let titleElement = try? document.select(".vehicle-details .vehicle-title").first(),
               let title = try? titleElement.text().trimmingCharacters(in: .whitespacesAndNewlines) {
                var resultText = String(format: "%@\n", title)

                // Extracting other details
                let detailsElements = try document.select(".d-flex.flex-wrap span")
                let totalDetails = detailsElements.array().count

                for (index, detailElement) in detailsElements.array().enumerated() {
                    if let detailText = try? detailElement.text().trimmingCharacters(in: .whitespacesAndNewlines) {
                        if detailText.contains(":") {
                            let components = detailText.components(separatedBy: ":")
                            if components.count == 2 {
                                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                                let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

                                // Check if it's the last detail
                                let isLastDetail = index == totalDetails - 1

                                // Append newline only if it's not the last detail
                                resultText += isLastDetail ? String(format: "%@: %@", key, value) : String(format: "%@: %@\n", key, value)
                            }
                        }
                    }
                }

                return "\n" + resultText
            }

            // If no specific details are found, return the entire HTML
            return motorcheckResultString
        } catch {
            throw NSError(domain: "Failed to parse Motorcheck response", code: 0, userInfo: nil)
        }
    }
}
