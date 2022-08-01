//
//  MenuBarCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Menu Bar Widget
struct MenuBarCoinView: View {
    // Koneksikan Fungsi Frontend dengan MenuBarCoinViewModel
    @ObservedObject var viewModel: MenuBarCoinViewModel
    
    var body: some View {
        HStack(spacing: 4.0) { // HStack Main Layout
            // Circle Color Indicator
            Image(systemName: "circle.fill")
                .foregroundColor(viewModel.color)
            
            // VStack Coin Name & Price Text
            VStack(alignment: .trailing, spacing: -2) {
                Text(viewModel.name)
                Text(viewModel.value)
            } // VStack Coin Name & Price Text
            .font(.caption)
        } // HStack Main Layout
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
        }
        // Invoke Coin Service dengan Combine
        .onAppear {
            viewModel.subscribeToService()
        }
    } // Body
} // Struct

struct MenuBarCoinView_Previews: PreviewProvider {
    static var previews: some View {
        // Default Value MenuBarCoinView
        MenuBarCoinView(viewModel: .init(name: "Bitcoin", value: "$40.000", color: .green))
    }
}
