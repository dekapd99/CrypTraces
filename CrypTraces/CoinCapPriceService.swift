//
//  CoinCapPriceService.swift
//  CrypTraces
//
//  Created by Deka Primatio on 16/07/22.
//

import Combine // Provided by Apple: Using publisher & subscriber pattern in our app
import Foundation
import Network // To implement monitoring network changes

/**
 * This is the service to create long-run persistent websocket connection to coincap.io server
 * with apple URL Session websocket.io task API, this API introduced by apple in iOS 13
 * So if your app still need to support iOS 12 and below you may considering using 3rd party library
 * such as a star screen to create websocket connection, and to communicate that with the ViewModel
 * that will use this service we are going to expose public combined publishers for the coin that got pushed
 * from the server as well as connection stated that got updated whenever the connection status of the server changes
 */

// Berisikan Price Service dari CoinCap.io dan URL Session Websocket.io
class CoinCapPriceService: NSObject {
    
    // Initialize URL Session & Websocket Task
    private let session = URLSession(configuration: .default)
    private var wsTask: URLSessionWebSocketTask? // Optional: Karena setiap kita disconnect harus sesegera mungkin reconnect dengan cara apapun dengan instance ini
    
    // Everytime new value arrives, tampilkan value baru tersebut dengan cara Subscriber dengan Combine Framework
    // Value Never -> Value dimana tidak ada nilai / throw error
    private let coinDictionarySubject = CurrentValueSubject<[String: Coin], Never>([:])
    // Var buat akses value baru dari coinDictionarySubject
    private var coinDictionary: [String: Coin] { coinDictionarySubject.value }
    
    // Variable buat Retry Connection
    private let connectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    // Var buat cek Koneksi: Connect or Disconnect
    private var isConnected: Bool { connectionStateSubject.value }
    
    // Fungsi API Connection to Webscoket & CoinCap
    func connect() { // Get All Cases from Coin Type
        let coins = CoinType.allCases
            .map { $0.rawValue } // Get Raw Value of the coin price
            .joined(separator: ",") // Seperate with , after 3 digits of number
        
        let url = URL(string: "wss://ws.coincap.io/prices?assets=\(coins)")! // Get URL from Sources
        wsTask = session.webSocketTask(with: url) // Set session with url
        wsTask?.delegate = self // invoke to delegate
        wsTask?.resume() // resume the connection
        self.receiveMessage() // Invoke Receive Message
    }
    
    // Fungsi Receive Message Response from API Server (Cukup Invoke websocket task dengan .receive
    private func receiveMessage() {
        wsTask?.receive{ [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message): // Sukses terima message response
                switch message {
                case .string(let text): // Passing Conversion String (text) to Data
                    print("Received Text Message: \(text)")
                    if let data = text.data(using: .utf8) {
                        self.onReceiveData(data)
                    }
                case .data(let data): // Passing Conversion String (text) to Swift Dictionary
                    print("Received Binary Message: \(data)")
                    self.onReceiveData(data)
                default: break
                }
                self.receiveMessage() // Recursive Websocket Task Works
                
            case .failure(let error): // Gagal terima message response
                print("Failed to Receive Message: \(error.localizedDescription)")
            }
        }
    }
    
    // Fungsi Record the Message (Price Result) & Convert it to Swift Dictionary
    private func onReceiveData(_ data: Data) {
        // Konversi String JSON dari data dengan JSONSerialization ke Swift Dictionary dalam bentuk String
        guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String:String] else {
            return
        }
        // Map newDictionary ke String Coin
        var newDictionary = [String: Coin]()
        // Logic Dictionary setiap Coin yang ada
        dictionary.forEach { (key, value) in
            let value = Double(value) ?? 0 // Convert String ke Double dengan Default Value = 0
            // Hasil konversi diatas dengan Nama Coin & Value-nya Assign ke newDictionary
            newDictionary[key] = Coin(name: key.capitalized, value: value)
        }
        
        // Override Current dictionary dengan cara merge dictionary dan menghasilkan yang baru
        let mergedDictionary = coinDictionary.merging(newDictionary) { $1 } // old, new in new
        // Publish downstream subscribers
        coinDictionarySubject.send(mergedDictionary)
    }
    
    // System will free up the resource: Subscriber Cleaning (don't amit new value again)
    deinit {
        coinDictionarySubject.send(completion: .finished)
        connectionStateSubject.send(completion: .finished)
    }
}

extension CoinCapPriceService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        
    }
}
