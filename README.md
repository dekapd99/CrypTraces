<!-- ABOUT THE PROJECT -->
<p align="center">
  <a href="#" target="_blank"><img src="iReader.png" width="200"></a>
</p>

# CrypTraces
Aplikasi iReader adalah aplikasi iOS Aplikasi Pemindai Barcode dan Teks dengan SwiftUI, AVKit, dan VisionKit (On Device Machine Learning Processing).

### Preview
<p align="center">
  <a href="#" target="_blank"><img src="1.png" width="200"></a>
  <a href="#" target="_blank"><img src="2.png" width="200"></a>
  <a href="#" target="_blank"><img src="3.png" width="200"></a>
</p>

<!-- ABOUT THE FILE & FOLDER STRUCTURE -->
## Folder & File Structure
Berikut struktur file dan folder pada iReader:

    .
    ├── iReaderApp.swift           # Root Project: Konfirgurasi AppViewModel
    ├── Info.plist                 # Privacy - Camera Usage Description
    ├── ContentView.swift          # Tampilan Beranda Aplikasi
    ├── Assets                     # Aset Logo dan Warna
    ├── AppViewModel.swift         # Berisikan Deklarasi Data Enum & Fungsi Main Thread
    └── DataScannerView.swift      # Berisikan Fungsi Wrapper DataScannerView yang disediakan oleh Apple untuk Scanning Data dengan Camera

<!-- List of Features -->
## Features:

* Filter Tipe Text Scanner (All, URL, Phone, Email, Address)
* Ping Scheduler
* CoinCap API
* Menu Bar macOS

<!-- Used Tools -->
## Build With:

* [Swift](https://www.swift.org/documentation/)
* [SwiftUI](https://developer.apple.com/documentation/swiftui/)
* [Xcode 14.0](https://developer.apple.com/xcode/)
* [VisionKit Framework](https://developer.apple.com/documentation/visionkit)
* [AVKit](https://developer.apple.com/documentation/avkit)

### Requirements
* [iOS 16.0 Beta](https://developer.apple.com/documentation/visionkit/datascannerviewcontroller?changes=_8_3)
* [Xcode 14.0](https://developer.apple.com/xcode/)

<!-- How to Install -->
## Installation
Untuk menggunakan repositori ini, ikutilah petunjuk penggunaan berikut dan pastikan git sudah terinstall pada komputer (semua perintah dilaksanakan pada `cmd.exe` atau `terminal`):

1. Lakukan download .zip atau `clone` repositori dengan cara:
```bash
git clone https://github.com/dekapd99/iReader.git
```

2. Jika sudah silahkan buka Project di Xcode.
3. Sambungkan iPhone dengan komputer Macbook Anda, dan pastikan untuk memilih iPhone tersebut pada Target Simulator (Kolom Device dibagian atas Xcode).
4. Enable Internet Access in Xcode for macOS App: Klik Project CrypTraces > Signing & Capabilities > App Sandbox (Checklist Network: Outgoing Connections (client))
5. Build & Run

<!-- What Kind of License? -->
## License
MIT License: Copyright (c) 2022 DK

<p align="right">(<a href="#top">back to top</a>)</p>
