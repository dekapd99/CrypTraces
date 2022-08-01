//
//  MenuBarCoinViewModel.swift
//  CrypTraces
//
//  Created by Deka Primatio on 18/07/22.
//

/**
 * Combine: Declarative Framework Swift API untuk Processing Value secara terus menerus dengan konsep Async
 * Cara kerjanya menggunakan operator publishers & subscribers
 * Publishers: mengekspos value yang berubah secara terus menerus
 * Subscribers: menerima value dari publishers
 * Disini Combine digunakan untuk Combine Wrap Multiple Publishers menjadi 1 Pipeline Subscribers
 */
import Combine
import Foundation
import SwiftUI

// Berisikan Fungsi Update Data Value Coin (Prices) di Menu Bar dengan Combine Subscriber
class MenuBarCoinViewModel: ObservableObject {
    @Published private(set) var name: String // Coin Name
    @Published private(set) var value: String // Coin Price Value
    @Published private(set) var color: Color // Circle Color: Connection Indicator
    // Untuk mengganti Default Coin & Value secara Realtime Value Changes via selectedCoinType
    @AppStorage("SelectedCoinType") private(set) var selectedCoinType = CoinType.bitcoin
    
    private let service: CoinCapPriceService // CoinCapService
    // Var Subscriptions Store & Cancellation Handler
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
    
    // Initializer CoinCapPriceService
    init(name: String = "", value: String = "", color: Color = .green, service: CoinCapPriceService = .init()) {
        // Assign associated instance property
        self.name = name
        self.value = value
        self.color = color
        self.service = service
    }
    
    // Fungsi Subscriber Repository: Combine Wrap Multiple Publishers menjadi 1 Pipeline Subscribers
    func subscribeToService() {
        service.coinDictionarySubject
            .combineLatest(service.connectionStateSubject) // Combine State Connection Service
            .receive(on: DispatchQueue.main) // Always invoke this Code inside the Main thread
            .sink { [weak self] _ in self?.updateView() } // Attaches a Subscribers with Closure based Behavior that will never fail to updateView
            .store(in: &subscriptions) // Store in Subscription
    }
    
    // Fungsi Update Tampilan (Coin Price Value)
    func updateView() {
        // Tampilkan Raw Value dari CoinType yang sudah di Deklarasikan
        let coin = self.service.coinDictionary[selectedCoinType.rawValue]
        self.name = coin?.name ?? selectedCoinType.description // Tampilkan Nama Coin yang dipilih
    
        // Cek Status Koneksi Service, Jika Connected maka Munculkan Realtime Price Value
        // Jika Disconnected maka tampilkan Offline
        if self.service.isConnected {
            // Cek Coin dan Format Value Coin dengan fungsi Formatter diatas
            // Jika tidak tampilkan Updating...
            if let coin = coin, let value = self.currencyFormatter.string(from: NSNumber(value: coin.value)) {
                self.value = value
            } else {
                self.value = "Updating..."
            }
        } else {
            self.value = "Offline"
        }
        // Sesuaikan Warna Circle Indicator dengan Status Koneksinya
        // Hijau = Connected & Merah = Disconnected
        self.color = self.service.isConnected ? .green : .red
    }
}
