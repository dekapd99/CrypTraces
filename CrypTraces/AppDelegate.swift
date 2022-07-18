//
//  AppDelegate.swift
//  CrypTraces
//
//  Created by Deka Primatio on 15/07/22.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // implicitly inject MenuBarCoinViewModel
    var menuBarCoinViewModel: MenuBarCoinViewModel!
    // implicitly inject MenuBarCoinViewModel
    var popoverCoinViewModel: PopoverCoinViewModel!
    // CoinCapService dari Model
    var coinCapService = CoinCapPriceService()
    // NS Status Item sebagai Property App Delegate
    var statusItem: NSStatusItem! // Individual Displayed System Menu Bar
    // Deklarasi Instance NSPopover -> Display Additional Content Related to the Existing Content
    let popover = NSPopover()
    
    /**
     * to add a custom view we need to access the window.contentview property inside this NSStatusItem
     * sadly apple does not expose this window as public property, but we can access it using failure for key
     * method passing window string as the key then cast the value to NSWindow
     */
    private lazy var contentView: NSView? = {
        let view = (statusItem.value(forKey: "window") as? NSWindow)?.contentView
        return view
    }()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupCoinCapService() // Aktifkan CoinCap Service di Main Thread
        setupMenuBar() // Tampilkan Menu Bar di Status Bar Mac
        setupPopover() // Tampilkan Pop Up setelah di klik
    }
    
    func setupCoinCapService() {
        coinCapService.connect() // konekin dengan coincap.io service
        coinCapService.startMonitorNetworkConnectivity() // start monitoring connectivity
    }
    
}

// MARK: - Menu Bar

// Extension Logic: Configuration Menu Bar
extension AppDelegate {
    
    // Fungsi Konfigurasi Menu Bar
    func setupMenuBar() {
        menuBarCoinViewModel = MenuBarCoinViewModel(service: coinCapService)
        // Assign Status Item Property, Load Status Item Spesific Space (Length = 64) di Status Bar
        statusItem = NSStatusBar.system.statusItem(withLength: 64)
        
        // Bentuk Menu Button di Menu Bar
        guard let contentView = self.contentView,
              let menuButton = statusItem.button
        else { return }

        // AppKit view -> Subclass NSView dari AppKit
        let hostingView = NSHostingView(rootView: MenuBarCoinView(viewModel: menuBarCoinViewModel)) // initialize with menuBarCoinViewModel
        hostingView.translatesAutoresizingMaskIntoConstraints = false // Menu Button Auto Layout
        contentView.addSubview(hostingView) // Invoke passing hostingView
        
        /**
         * Configuration Adding Data to Menu Button dengan Auto Layout
         * We are going to anchor all of these hosting view edges to the content view
         */
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: contentView.topAnchor),
            hostingView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            hostingView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            hostingView.leftAnchor.constraint(equalTo: contentView.leftAnchor)
        ])
        
        // Default action message selector with control
        menuButton.action = #selector(menuButtonClicked)
    }
    
    // Fungsi menu button ketika di klik dengan Obj-C target action selector mechanism
    @objc func menuButtonClicked() {
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        
        /**
         * Remove arrow di Pop Up
         * Create our positioningView using the menu button that bounce as the frame and then edit the subview
         * of the menu button then we will use this position field as the anchor of the pop over
         */
        guard let menuButton = statusItem.button else { return }
        let positioningView = NSView(frame: menuButton.bounds) // Deklarasi positioningView via init NSView
        positioningView.identifier = NSUserInterfaceItemIdentifier("positioningView") // pass indetifier ke NSUserInterfaceItemIdentifier
        menuButton.addSubview(positioningView) // Invoke menuButton ke subview positioningView
        
        popover.show(relativeTo: menuButton.bounds, of: menuButton, preferredEdge: .maxY)
        menuButton.bounds = menuButton.bounds.offsetBy(dx: 0, dy: menuButton.bounds.height)
        popover.contentViewController?.view.window?.makeKey()
    }
}

// MARK: - Popover

// Extension Logic: Custom Pop Up
extension AppDelegate: NSPopoverDelegate {
    
    // Fungsi Konfigurasi Pop Up
    func setupPopover() {
        popoverCoinViewModel = .init(service: coinCapService)
        popover.behavior = .transient // Close Pop up kalo user klik di luar kotak Pop up
        popover.animates = true
        popover.contentSize = .init(width: 240, height: 280) // ukuran pop up
        popover.contentViewController = NSViewController() // assign contentView controller via init NSViewController
        // Set Content View dengan NSHostingView -> set frame .infinity agar bisa mengambil seluruh space yang disediakan controlview
        popover.contentViewController?.view = NSHostingView(
            rootView: PopoverCoinView(viewModel: popoverCoinViewModel).frame(maxWidth: .infinity, maxHeight: .infinity).padding()
        )
        popover.delegate = self // Supaya view window click gak stack ketika setiap di click
    }
    
    // Fungsi Close Pop Up Close Disapear
    func popoverDidClose(_ notification: Notification) {
        // Cek semua subviews, cari First Elements di Collection Closure Identifier positioningView
        let positioningView = statusItem.button?.subviews.first {
            $0.identifier == NSUserInterfaceItemIdentifier("positioningView")
        }
        positioningView?.removeFromSuperview() // invoke positioningView kemudian remove dari Superview
    }
}
