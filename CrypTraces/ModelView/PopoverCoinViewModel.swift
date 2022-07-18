//
//  PopoverCoinViewModel.swift
//  CrypTraces
//
//  Created by Deka Primatio on 18/07/22.
//

import Combine
import Foundation
import SwiftUI

class PopoverCoinViewModel: ObservableObject {
    @Published private(set) var title: String // Coin Name
    @Published private(set) var subtitle: String // Coin Price Value
    @Published private(set) var coinTypes: [CoinType] // Circle Color Connection Indicator
    // Reflects a value from users default & invalidates of view on a change of price value dengan key SelectedCoinType
    @AppStorage("SelectedCoinType") var selectedCoinType = CoinType.bitcoin
    
    private let service: CoinCapPriceService // CoinCapService
    // when we subscribe to publishers, it will return a subscription that we need to store & handle cancellation of removal of that subscription
    private var subscriptions = Set<AnyCancellable>()
    
    // Format Penulisan Angka Currency dalam bentuk USD $
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    // initializer
    init(title: String = "", subtitle: String = "", coinTypes: [CoinType] = CoinType.allCases, service: CoinCapPriceService = .init()) {
        // assign associated instance property
        self.title = title
        self.subtitle = subtitle
        self.coinTypes = coinTypes
        self.service = service
    }
    
    // Fungsi Subscriber Repository
    func subscribeToService() {
        // cek the service
        service.coinDictionarySubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateView() }
            .store(in: &subscriptions)
    }
    
    // Fungsi Update Tampilan (Coin Price Value)
    func updateView() {
        let coin = self.service.coinDictionary[selectedCoinType.rawValue] // grab the name of coinType that we will to be show
        self.title = coin?.name ?? selectedCoinType.description // name publish property with fallback of selected coin description
        
        // cek coin dan format value coin dengan fungsi formatter diatas
        // jika tidak tampilkan Updating...
        if let coin = coin, let value = self.currencyFormatter.string(from: NSNumber(value: coin.value)) {
            self.subtitle = value
        } else {
            self.subtitle = "Updating..."
        }
    }
    
    func valueText(for coinType: CoinType) -> String {
        // cek coin dan format value coin dengan fungsi formatter diatas
        // jika tidak tampilkan Updating...
        if let coin = service.coinDictionary[coinType.rawValue], let value = self.currencyFormatter.string(from: NSNumber(value: coin.value)) {
            return value
        } else {
            return "Updating..."
        }
    }
}
