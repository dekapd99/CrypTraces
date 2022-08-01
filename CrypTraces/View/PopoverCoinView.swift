//
//  PopoverCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Popup
struct PopoverCoinView: View {
    // Koneksikan Fungsi Frontend dengan PopoverCoinViewModel
    @ObservedObject var viewModel: PopoverCoinViewModel
    
    var body: some View {
        // VStack Main Layout
        VStack(spacing: 16.0) {
            VStack { // VStack Choosen Coin
                Text(viewModel.title)
                    .font(.largeTitle)
                Text(viewModel.subtitle)
                    .font(.title.bold())
            } // VStack Choosen Coin
            
            Divider() // Widget Divider: Garis Pemisah
            
            // Picker Coin Selection
            Picker("Select Coin", selection: $viewModel.selectedCoinType) {
                
                ForEach(viewModel.coinTypes) { type in
                    HStack {
                        Text(type.description).font(.headline)
                        Spacer()
                        Text(viewModel.valueText(for: type))
                            .frame(alignment: .trailing)
                            .font(.body)
                        
                        // URL Link to Coin via Browser
                        Link(destination: type.url) {
                            Image(systemName: "safari")
                        }
                    }
                    .tag(type)
                    
                } // ForEach of Declared CoinTypes
            } // Picker Coin Selection
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()
            
            Divider() // Widget Divider: Garis Pemisah
            
            // Close App & Killing the Process of the App
            Button("Quit") {
                NSApp.terminate(self)
            }
        } // VStack Main Layout
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
        }
        // Invoke Coin Service dengan Combine
        .onAppear {
            viewModel.subscribeToService()
        }
    } // Body
} // Struct

struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        // Default Value PopoverCoinView
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40.000"))
    }
}
