//
//  MenuBarCoinViewModel.swift
//  CrypTraces
//
//  Created by Deka Primatio on 18/07/22.
//

import Combine
import Foundation
import SwiftUI

// Berisikan
class MenuBarCoinViewModel: ObservableObject {
    @Published private(set) var name: String // Coin Name
    @Published private(set) var value: String // Coin Price Value
    @Published private(set) var color: Color // Circle Color Connection Indicator
    // Reflects a value from users default & invalidates of view on a change of price value dengan key SelectedCoinType
    @AppStorage("SelectedCoinType") private(set) var selectedCoinType = CoinType.bitcoin
    
    private let service: CoinCapPriceService // CoinCapService
    // when we subscribe to publishers, it will return a subscription that we need to store & handle cancellation of removal of that subscription
    private var subscriptions = Set<AnyCancellable>()
    
    // Format Penulisan Angka Currency dalam bentuk USD $
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter
    }()
    
    // initializer
    init(name: String = "", value: String = "", color: Color = .green, service: CoinCapPriceService = .init()) {
        // assign associated instance property
        self.name = name
        self.value = value
        self.color = color
        self.service = service
    }
    
    // Fungsi
    func subscribeToService() {
        // Combine multiple publishers menjadi 1 pipeline
        service.coinDictionarySubject
            .combineLatest(service.connectionStateSubject) // combine state connection service
            .receive(on: DispatchQueue.main) // this code inside the scene will always be invoke inside the main thread
            .sink { [weak self] _ in self?.updateView() } // attaches a subscribers with closure based behavior that will never fail to updateView
            .store(in: &subscriptions) // store in subscription
    }
    
    // Fungsi Update Tampilan (Coin Price Value)
    func updateView() {
        let coin = self.service.coinDictionary[selectedCoinType.rawValue] // grab the name of coinType that we will to be show
        self.name = coin?.name ?? selectedCoinType.description // name publish property with fallback of selected coin description
        
        // cek the services is connected ? jika iya maka munculkan price value updatenya
        // Jika tidak maka tampilkan Offline
        if self.service.isConnected {
            // cek coin dan format value coin dengan fungsi formatter diatas
            // jika tidak tampilkan Updating...
            if let coin = coin, let value = self.currencyFormatter.string(from: NSNumber(value: coin.value)) {
                self.value = value
            } else {
                self.value = "Updating..."
            }
        } else {
            self.value = "Offline"
        }
        // Menyesuaikan koneksi dengan warna
        self.color = self.service.isConnected ? .green : .red
    }
}
