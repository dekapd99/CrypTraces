//
//  MenuBarCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Awal Widget
struct MenuBarCoinView: View {
    
    @ObservedObject var viewModel: MenuBarCoinViewModel
    
    var body: some View {
        HStack(spacing: 4.0) {
            Image(systemName: "circle.fill")
                .foregroundColor(viewModel.color)
            
            VStack(alignment: .trailing, spacing: -2) {
                Text(viewModel.name)
                Text(viewModel.value)
            }
            .font(.caption)
        }
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
        }
        // Invoke whenever use Service
        .onAppear {
            viewModel.subscribeToService()
        }
    }
}

struct MenuBarCoinView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarCoinView(viewModel: .init(name: "Bitcoin", value: "$40.000", color: .green))
    }
}
