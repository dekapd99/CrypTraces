//
//  CoinCapPriceService.swift
//  CrypTraces
//
//  Created by Deka Primatio on 16/07/22.
//

/**
 * Combine: Declarative Framework Swift API untuk Processing Value secara terus menerus dengan konsep Async
 * Cara kerjanya menggunakan operator publishers & subscribers
 * Publishers: mengekspos value yang berubah secara terus menerus
 * Subscribers: menerima value dari publishers
 * Disini Combine digunakan untuk Mengekspos perubahan Value Coin (prices), Menerima hasil perubahan tersebut,
 * dan Menampilkannya ke dalam aplikasi & log secara Realtime.
 */
import Combine
import Foundation
/**
 * Network: Framework untuk Mengirim dan Menerima Data menggunakan Protocol Transport & Security
 * Cara kerjanya menggunakan URLSession load HTTP- dan URL-Based Resource dari CoinCap & Websocket
 * Disini Network digunakan untuk monitoring network changes dengan NWPathMonitor
 */
import Network

/**
 * Cara kerja Service ini, pertama buat koneksi WebSocket ke CoinCap server dengan URLSession WebSocketTask API
 * Kedua, buat koneksi WebSocket untuk berkomunikasi di ViewModel
 * Ketiga, gunakan Combine Publishers untuk Coin-coin yang ingin ditampilkan dari Server CoinCap
 * Keempat, update seluruh data ketika status koneksi internet dari server berubah
 */

/** Berisikan Fungsi API Service:
 * API Connection to WebSocket (WS) & CoinCap (CC)
 * Monitoring perubahan koneksi (On / Off Connectivity)
 * Receive Message Response from API Server
 * Record the Message (Price Result) & Convert it to Swift Dictionary
 * Schedule Ping
 * Reconnection & Task Clearing from Resources
 */
class CoinCapPriceService: NSObject {
    
    // Initialize URL Session & Websocket Task
    private let session = URLSession(configuration: .default)
    // Optional: Karena setiap kita disconnect harus sesegera mungkin reconnect dengan cara apapun dengan instance ini
    private var wsTask: URLSessionWebSocketTask?
    private var pingTryCount = 0 // Default Ping Counter
    
    // Setiap value baru muncul, tampilkan value baru tersebut dengan Subscribers
    // Never>([:]) -> Value tidak ada nilai / throw error
    let coinDictionarySubject = CurrentValueSubject<[String: Coin], Never>([:])
    // Var buat akses value baru dari coinDictionarySubject
    var coinDictionary: [String: Coin] { coinDictionarySubject.value }
    
    // Var Retry Connection
    let connectionStateSubject = CurrentValueSubject<Bool, Never>(false)
    // Var Status Koneksi: Connect or Disconnect
    var isConnected: Bool { connectionStateSubject.value }
    // Var Monitor Network Interface (wifi, ethernet, etc.) from Network Module
    private let monitor = NWPathMonitor()
    
    // Fungsi API Connection to Webscoket & CoinCap
    func connect() { // Get All Cases from CoinType
        let coins = CoinType.allCases
            .map { $0.rawValue } // Get Raw Value dari Coin Price
            .joined(separator: ",") // Setiap Coin dipisahkan dengan ,
        
        // Get URL from Sources: WS & CC
        let url = URL(string: "wss://ws.coincap.io/prices?assets=\(coins)")!
        wsTask = session.webSocketTask(with: url) // Set Session dengan WSTask url
        wsTask?.delegate = self // Invoke ke delegate
        wsTask?.resume() // Resume Connection
        self.receiveMessage() // Invoke Receive Message
        self.schedulePing() // Invoke Ping Scheduler
    }
    
    // Fungsi Monitoring Perubahan Koneksi (On / Off Connectivity)
    func startMonitorNetworkConnectivity() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Unwrap self & assign task
            guard let self = self else { return }
            // Cek status jika .satisfied & wsTask = nil maka koneksikan dengan Server
            if path.status == .satisfied, self.wsTask == nil {
                self.connect()
            }
            // Cek status jika tidak .satisfied maka Clear Connection
            if path.status != .satisfied {
                self.clearConnection()
            }
        }
        // Start monitoring dengan main DispatchQueue
        monitor.start(queue: .main)
    }
    
    // Fungsi Receive Message Response from API Server (Cukup Invoke websocket task dengan .receive)
    private func receiveMessage() {
        wsTask?.receive{ [weak self] result in
            // Unwrap self & assign task
            guard let self = self else { return }
            switch result {
            // Sukses terima Message Response
            case .success(let message):
                switch message {
                
                // Passing Conversion String (text) to Data
                case .string(let text):
                    print("Received Text Message: \(text)")
                    // Cek data text jika bertipe .utf8 (common type)
                    if let data = text.data(using: .utf8) {
                        self.onReceiveData(data)
                    }
                    
                // Passing Conversion String (text) to Swift Dictionary
                case .data(let data):
                    print("Received Binary Message: \(data)")
                    self.onReceiveData(data)
                    
                default: break
                }
                self.receiveMessage() // Recursive Websocket Task Works
                
            // Gagal terima Message Response
            case .failure(let error):
                print("Failed to Receive Message: \(error.localizedDescription)")
            }
        }
    }
    
    // Fungsi Record the Message (Price Result) & Convert Message ke Swift Dictionary
    private func onReceiveData(_ data: Data) {
        // Konversi String JSON Data dengan JSONSerialization ke Swift Dictionary dalam bentuk String
        guard let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String:String] else {
            return
        }
        
        var newDictionary = [String: Coin]() // Map newDictionary ke String Coin
        // Logic Dictionary setiap Coin yang ada
        dictionary.forEach { (key, value) in
            let value = Double(value) ?? 0 // Convert String ke Double dengan Default Value = 0
            // Hasil konversi diatas, Assign ke newDictionary dengan Nama Coin & Value-nya
            newDictionary[key] = Coin(name: key.capitalized, value: value)
        }
        
        // Override Current dictionary dengan cara merge dictionary dan menghasilkan yang baru
        let mergedDictionary = coinDictionary.merging(newDictionary) { $1 } // old, new in new
        // Publish Downstream Subscribers ke coinDictionarySubject
        coinDictionarySubject.send(mergedDictionary)
    }
    
    // Fungsi Ping Scheduler
    private func schedulePing() {
        // Capture identifier Viewerization Websocket Task dengan taskIdentifier (uniquely identifying the task within a given session) dengan default fallback value = -1
        let identifier = self.wsTask?.taskIdentifier ?? -1
        // Schedule Closure the Executed function after 5 seconds inside the Main Thread
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            // Unwrap self & Assign task
            // Make sure current taskIdentifier sama dengan Identifier 5 seconds diatas dan lanjutkan ke Code selanjutnya
            guard let self = self, let task = self.wsTask,
                  task.taskIdentifier == identifier
            else { // In case this guard failed then just return
                return
            }

            // Jika Task State is Running & Ping Counter < 2
            // Maka Increment Ping Counter & kirim Ping dengan task.sendPing
            if task.state == .running, self.pingTryCount < 2 {
                self.pingTryCount += 1
                print("Ping: Send Ping \(self.pingTryCount)")
                
                // Send the Ping to Server
                task.sendPing { [weak self] error in
                    // Jika Terjadi Error pada Saat pengiriman Ping maka Print Error-nya
                    if let error = error {
                        print("Ping Failed: \(error.localizedDescription)")
                    
                    // Jika Tidak, periksa TaskIndetifier == identifier
                    } else if self?.wsTask?.taskIdentifier == identifier {
                        self?.pingTryCount = 0 // Reset Ping Counter kembali jadi 0
                    }
                }
                // Always Call This Function Every 5 Secs to Schedule the Ping
                self.schedulePing()
            } else {
                // Jika Task State is Not Running maka segera jalankan fungsi Reconnect
                self.reconnect()
            }
        }
    }
    
    // Fungsi Reconnect -> Clear Connection dulu baru koneksiin ulang
    private func reconnect() {
        self.clearConnection() // Disconnect dulu
        self.connect() // Koneksiin Ulang
    }
    
    // Clear Task & Connection -> Fungsi Disconnect Handle and Handling the Task
    func clearConnection() {
        self.wsTask?.cancel() // Cancel WebSocket Task
        self.wsTask = nil // Set WebSocket task to nil
        self.pingTryCount = 0 // Reset Ping Counter
        self.connectionStateSubject.send(false) // Disconnect the WebSocket Service
    }
    
    // System will free up the resource: Subscriber Cleaning (don't amit new value again)
    deinit {
        coinDictionarySubject.send(completion: .finished)
        connectionStateSubject.send(completion: .finished)
    }
}

// Extension CoinCapPriceService: Succesfully Connect to WebSocket Server & Cancel Current Task to Disconnect from the Server
extension CoinCapPriceService: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        // This will be Invoke when we SUCCESFULLY connected to WebSocket Server
        // Update connectionStateSubject
        self.connectionStateSubject.send(true)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        // This will be Invoke when we CANCEL the Current Task then Disconnect from the Server
        // Update disconnectedState
        self.connectionStateSubject.send(false)
    }
}
