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
    private var pingTryCount = 0 // Default Ping Counter
    
    // Everytime new value arrives, tampilkan value baru tersebut dengan cara Subscriber dengan Combine Framework
    // Value Never -> Value dimana tidak ada nilai / throw error
    let coinDictionarySubject = CurrentValueSubject<[String: Coin], Never>([:])
    // Var buat akses value baru dari coinDictionarySubject
    var coinDictionary: [String: Coin] { coinDictionarySubject.value }
    
    // Variable buat Retry Connection
    let connectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    // Var buat cek Koneksi: Connect or Disconnect
    var isConnected: Bool { connectionStateSubject.value }
    // variable buat monitor network interface (wifi, ethernet, etc.) from Network Module
    private let monitor = NWPathMonitor()
    
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
        self.schedulePing() // invoke schedule ping
    }
    
    // Fungsi Monitoring perubahan koneksi (On / Off Connectivity)
    func startMonitorNetworkConnectivity() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Unwrap self & assign task
            guard let self = self else { return }
            // cek status jika .satisfied & wsTask = nil maka koneksikan
            if path.status == .satisfied, self.wsTask == nil {
                self.connect()
            }
            // Cek status jika tidak .satisfied clear connection
            if path.status != .satisfied {
                self.clearConnection()
            }
        }
        // start monitoring dengan main dispatchqueue
        monitor.start(queue: .main)
    }
    
    // Fungsi Receive Message Response from API Server (Cukup Invoke websocket task dengan .receive
    private func receiveMessage() {
        wsTask?.receive{ [weak self] result in
            // Unwrap self & assign task
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
    
    // Fungsi Schedule Ping
    private func schedulePing() {
        // Capture identifier Viewerization Websocket Task dengan taskIdentifier (uniquely identifying the task within a given session) dengan default fallback value = -1
        let identifier = self.wsTask?.taskIdentifier ?? -1
        // Schedule closure the executed function after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            // Unwrap self & assign task
            guard let self = self, let task = self.wsTask,
                  task.taskIdentifier == identifier // Make sure current taskIdentifier sama dengan identifier that we have captures 5 seconds earlier the continue the code
            else { // in case this guard failed then just return
                return
            }
            /**
             * we are going to check the property in utilization websocket task whereas this active suspended
             * or in the process of being cancelled or completed
             * this if task.state == .running is not getting updated if there is a sudden internet connection lost
             * there will be an internal websocket connection timeout which is around 30 seconds up to 2 minutes
             * only in that between the timeout this task.state will change is not equal to running
             * i think the timeout is too long for us to wait we need to just disconnect immediately in that situation when
             * sudden internet connection lost happening the trick is using pingTryCount as counter and increment that
             */
            // Cek if the state is running
            if task.state == .running, self.pingTryCount < 2 {
                self.pingTryCount += 1
                // if it is then send the ping dengan task.sendPing
                print("Ping: Send Ping \(self.pingTryCount)")
                task.sendPing { [weak self] error in
                    if let error = error { // send error of ping
                        print("Ping Failed: \(error.localizedDescription)")
                    // we are going to cek this self wsTask = taskIdentifier sama dengan identifier that we have captures
                    } else if self?.wsTask?.taskIdentifier == identifier {
                        // reset pingTryCount in case of the ping success (we got the pong back from server)
                        self?.pingTryCount = 0
                    }
                }
                // we need to call this function again so it will keep on calling this method every 5 seconds to schedule the ping & cek condition of the states
                self.schedulePing()
            } else {
                // if the state is not running then reconnect
                self.reconnect()
            }
        }
    }
    
    // Fungsi Reconnect -> Clear Connection dulu baru koneksiin ulang
    private func reconnect() {
        self.clearConnection() // Disconnect dulu
        self.connect() // Koneksiin Ulang
    }
    
    // Clear Task & Connection -> Fungsi Handle Disconnect and Handling the Task
    func clearConnection() {
        self.wsTask?.cancel() // Cancel websocket task
        self.wsTask = nil // set websocket task to nil
        self.pingTryCount = 0 // Reset Ping Count
        self.connectionStateSubject.send(false) // disconnect the connection service
    }
    
    // System will free up the resource: Subscriber Cleaning (don't amit new value again)
    deinit {
        coinDictionarySubject.send(completion: .finished)
        connectionStateSubject.send(completion: .finished)
    }
}

extension CoinCapPriceService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // this will be invoke when we successfully connected to websocket server
        // update connectionStateSubject
        self.connectionStateSubject.send(true)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // this will be invoke when we cancel the current task then disconnect from the server
        // update disconnectedState
        self.connectionStateSubject.send(false)
    }
}
