//
//  ContentView.swift
//  searchCars
//
//  Created by Paul Murnane on 15/12/2023.
//

import SwiftUI
import UIKit
import MobileCoreServices
import WebKit



struct ContentView: View {
    @State private var carRegistration = ""
    @State private var carDetails = ""
    @State private var isLoading = false
    @State private var isWebViewPresented = false
    
    let backgroundImages = ["b1", "b2", "b3", "b4", "b5", "b6", "b7"]
    @State private var selectedBackgroundImage = "b1"

    var body: some View {
        NavigationView {
            VStack {
                // Enter car registration
                TextField("Enter car registration", text: $carRegistration)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .multilineTextAlignment(.center)
                    .padding(.top, 50)

                // Search button
                Button("Search") {
                    getCarDetails()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)

                // Fetching Details loader (only shows if lookup is happening)
                if isLoading {
                    ProgressView("Fetching car details...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .foregroundColor(.white)
                        .padding()
                } else {
                    Text(carDetails)
                        .padding()
                        .multilineTextAlignment(.center)
                        .background(carDetails.isEmpty ? nil : Color.gray.opacity(0.8))
                        .foregroundColor(carDetails.isEmpty ? Color.black : Color.black)
                }

                // Share button to share to various applications. Only shows up if a car has actually been returned
                Button("Share") {
                    share()
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .opacity(carDetails.contains("CC") ? 1.0 : 0.0)

                Spacer()

                // If no car details have been returned for the inputted reg, an open website button appears
                Button("Open Website") {
                    isWebViewPresented.toggle()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .sheet(isPresented: $isWebViewPresented) {
                    WebView(url: URL(string: "https://www.carcheck.ie")!)
                }
                .opacity(carDetails.contains("Unknown registration:") ? 1.0 : 0.0)

                // Navigation button to go to the SavedCarsView
                NavigationLink(destination: SavedCarsView()) {
                    Text("History")
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(15)
                        .padding()
                }
            }
            .padding()
            // Just to have a different background image each time the app opens (found in assets)
            .background(
                Image(selectedBackgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        selectedBackgroundImage = backgroundImages.randomElement() ?? "defaultImage"
                    }
            )
            .ignoresSafeArea()
        }
    }
    
    //Function to call the getCarDetails in the CarService class
    private func getCarDetails() {
        isLoading = true
        
        let inputreg = self.carRegistration
        
        CarServiceImpl().getCarDetails(registration: carRegistration) { result in
           DispatchQueue.main.async {
                isLoading = false
                //switch for the results, success or failure
                switch result {
                    //if success put the results string into details
                case .success(let details):
                    //if details contains the string it means lookup has failed
                    if details.contains("<!DOCTYPE html") {
                        self.carDetails = "Unknown registration: \(self.carRegistration)"
                    } else {
                        self.carDetails = details
                        DBHelper.shared.insertCar(registration: inputreg, details: details)
                    }
                    //if it fails, tell the error to the user in the textbox
                case .failure(let error):
                    self.carDetails = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    //Sharing function, opens up the sharing window for the user to choose where they want to results to go
    private func share() {
        let rn = "Reg Number: "
        let uc = self.carRegistration.uppercased()
        let message = "\(rn) \(uc)\n\(carDetails)"
        
        //put the car details message into the pasteboard
        UIPasteboard.general.string = message
        
        //open the share box with the item of the car details
        let activityViewController = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        //exclude certain activity types as they are uneecessary for this type of content
        activityViewController.excludedActivityTypes = [
            .saveToCameraRoll,
            .addToReadingList,
            .postToFlickr,
            .postToVimeo
        ]
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
}
    
    //preview provider of an Iphone 15 with darkmdoe
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView()
                .previewDevice("iPhone 11")
                .preferredColorScheme(.dark)
        }
    }
}

//Struct to open the webview of carcheck.ie if the user presses the button
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}
