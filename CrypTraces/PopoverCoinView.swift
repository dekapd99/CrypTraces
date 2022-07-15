//
//  PopoverCoinView.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Tampilan Frontend Popup
struct PopoverCoinView: View {
    var body: some View {
        VStack(spacing: 16.0) {
            VStack {
                Text("Bitcoin")
                    .font(.largeTitle)
                Text("$40.000")
                    .font(.title.bold())
            }
            
            Divider() // Widget Divider: Garis Pemisah
            
            // Close App by Killing the Process of the App
            Button("Quit") {
                NSApp.terminate(self)
            }
        }
    }
}

struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView()
    }
}
