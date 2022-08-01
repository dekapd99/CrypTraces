//
//  CrypTracesApp.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import SwiftUI

// Main App dengan Base Empty View di MacOS App
@main
struct CrypTracesApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            EmptyView().frame(width: 0, height: 0) // Base Empty View in Mac
        }
    }
}
