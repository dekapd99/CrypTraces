//
//  PopoverCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Popup
struct PopoverCoinView: View {
    
    @ObservedObject var viewModel: PopoverCoinViewModel
    
    var body: some View {
        VStack(spacing: 16.0) {
            VStack {
                Text(viewModel.title)
                    .font(.largeTitle)
                Text(viewModel.subtitle)
                    .font(.title.bold())
            }
            
            Divider() // Widget Divider: Garis Pemisah
            
            Picker("Select Coin", selection: $viewModel.selectedCoinType) {
                
                ForEach(viewModel.coinTypes) { type in
                    HStack {
                        Text(type.description).font(.headline)
                        Spacer()
                        Text(viewModel.valueText(for: type))
                            .frame(alignment: .trailing)
                            .font(.body)
                        
                        Link(destination: type.url) {
                            Image(systemName: "safari")
                        }
                    }
                    .tag(type)
                    
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()
            
            Divider() // Widget Divider: Garis Pemisah
            
            // Close App by Killing the Process of the App
            Button("Quit") {
                NSApp.terminate(self)
            }
        }
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
        }
        .onAppear {
            viewModel.subscribeToService()
        }
    }
}

struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40.000"))
    }
}
