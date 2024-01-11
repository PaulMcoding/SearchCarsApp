//
//  SearchBar.swift
//  searchCars
//
//  Created by Paul Murnane on 19/12/2023.
//

import Foundation
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSearch: () -> Void

    var body: some View {
        HStack {
            TextField("Search", text: $text, onCommit: {
                onSearch()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 10)

            Button(action: {
                onSearch()
            }) {
                Image(systemName: "magnifyingglass")
            }
            .padding(.trailing, 10)
        }
        .padding()
    }
}
