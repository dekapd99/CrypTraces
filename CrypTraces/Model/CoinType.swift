//
//  CoinType.swift
//  CrypTraces
//
//  Created by Deka Primatio on 16/07/22.
//

import Foundation

// Deklarasi Data (Domain Model): Tipe-tipe Coin Crypto (Hard Code) Bisa juga dilakukan secara Query
enum CoinType: String, Identifiable, CaseIterable {
    
    case bitcoin
    case ethereum
    case monero
    case litecoin
    case dogecoin
    
    // Compute Property dari coincap.io
    var id: Self { self }
    // Button Link to see more data
    var url: URL { URL(string: "https://coincap.io/assets/\(rawValue)")! }
    var description: String { rawValue.capitalized } // Title di UI
}
