//
//  MenuBarCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Awal Widget
struct MenuBarCoinView: View {
    var body: some View {
        HStack(spacing: 4.0) {
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .trailing, spacing: -2) {
                Text("Bitcoin")
                Text("$40.000")
            }
            .font(.caption)
        }
    }
}

struct MenuBarCoinView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarCoinView()
    }
}
