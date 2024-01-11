//
//  SavedCarsView.swift
//  searchCars
//
//  Created by Paul Murnane on 18/12/2023.
//

import SwiftUI

struct SavedCarsView: View {
    @State private var savedCars: [Car] = [] // Assuming Car is the model you've defined
    @State private var filteredCars: [Car] = []
    @State private var selectedCar: Car?
    @State private var showAlert = false
    @State private var searchText = ""
    @State private var isRefreshing = false

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearch: performSearch)
                
                List {
                    ForEach(filteredCars, id: \.id) { car in
                        VStack(alignment: .leading) {
                            Text("Registration: \(car.registration)")
                            Text("Details: \(car.details)")
                        }
                        .contextMenu {
                            Button("Delete") {
                                selectedCar = car
                                showAlert.toggle()
                            }
                            
                            Button("Share") {
                                shareCar(car)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                copyToClipboard(car)
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteCars)
                }
                .refreshable {
                    await refreshCars()
                }
                .navigationBarTitle("Saved Cars", displayMode: .inline)
                .onAppear {
                    refreshCars()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Car"),
                    message: Text("Are you sure you want to delete \(selectedCar?.registration ?? "")?"),
                    primaryButton: .default(Text("Cancel")),
                    secondaryButton: .destructive(Text("Delete"), action: {
                        if let carToDelete = selectedCar {
                            deleteCar(carToDelete)
                        }
                    })
                )
            }
        }
    }


    private func deleteCars(at offsets: IndexSet) {
        for index in offsets {
            selectedCar = filteredCars[index]
            showAlert.toggle()
        }
    }
    
    private func copyToClipboard(_ car: Car) {
        let details = car.share()
        UIPasteboard.general.string = details
    }
    
    private func refreshCars() {
        isRefreshing = true
        searchText = ""
        DispatchQueue.global().async {
            let newCars = DBHelper.shared.getAllCars()
            DispatchQueue.main.async {
                savedCars = newCars
                filterCars()
                isRefreshing = false
            }
        }
    }

    private func performSearch() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        filterCars()
    }

    private func filterCars() {
        if searchText.isEmpty {
            // If the search text is empty, show all cars
            filteredCars = savedCars
        } else {
            // Filter cars based on the search text
            filteredCars = savedCars.filter { car in
                car.registration.localizedCaseInsensitiveContains(searchText) ||
                car.details.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    private func deleteCar(_ car: Car) {
        DBHelper.shared.deleteCar(car)
        savedCars = DBHelper.shared.getAllCars()
        filterCars()
    }

    private func shareCar(_ car: Car) {
        let message = car.share()

        // Present a share sheet using UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: [message], applicationActivities: nil)

        // Get the current UIWindow to present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}

struct SavedCarsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedCarsView()
    }
}
