# Product Requirements Document (PRD) — Flutter POS UMKM (Offline-First)

## 1. Metadata Proyek
* **Nama Produk**: PosUmkm (Flutter Offline-First POS)
* **Platform**: Android & iOS (Dukungan Responsif: Smartphone & Tablet Kasir)
* **Target Pengguna**: Kasir & Pemilik UMKM F&B (Booth Minuman & Makanan Ringan: *Lumpia Ubi/Celembu, Mojito Series, Milk Boba Series, Pure Matcha, Potato Korean Cheese Bread*)
* **Filosofi Utama**: **Local-First & Zero-Latency** (Operasional transaksi 100% lancar tanpa internet, latensi UI < 16ms, database lokal adalah *single source of truth*, sinkronisasi mutasi ke Cloud Server di latar belakang secara asinkron berbasis CRDT).

---

## 2. Latar Belakang & Masalah (Problem Statement)
Operasional UMKM F&B di lapangan menghadapi tantangan nyata:
1. **Koneksi Internet Tidak Stabil**: Bazaar, ruko pinggir jalan, atau food court sering mengalami gangguan sinyal. Sistem POS tidak boleh bergantung pada server cloud saat kasir melayani antrean.
2. **Kebutuhan Kecepatan Kasir (High Velocity)**: Kasir harus menyelesaikan pesanan dalam hitungan detik tanpa *loading spinner* atau lag.
3. **Kasir Tidak Memegang Rekening / M-Banking Owner**: Saat pembeli membayar QRIS statis outlet, kasir tidak bisa mengecek saldo rekening pemilik. Kasir rawan ditipu oleh screenshot palsu atau pembeli yang salah mengetik nominal.
4. **Verifikasi Bukti Bayar Anti-Manipulasi (100% Offline)**: Kasir membutuhkan cara instan untuk memverifikasi bukti bayar di HP pembeli tanpa kuota internet, memeriksa tanggal/jam secara ketat agar screenshot lama tertolak, serta menyimpan foto bukti bayar tersebut langsung ke dalam riwayat struk pesanan.
5. **Kebutuhan Owner Memantau dari Rumah (Zero Hassle)**: Pemilik toko sering kali tidak berada di gerai sepanjang hari. Owner membutuhkan cara paling praktis untuk menerima laporan harian (pemisahan uang tunai vs QRIS, menu terlaris, rekap kas laci) langsung ke WhatsApp pribadi setiap malam, serta kemudahan mengekspor file Excel (`.xlsx`) bulanan dengan 1 klik tanpa harus datang ke outlet.

---

## 3. Persona Pengguna
1. **Kasir (Operator)**:
   * Mengutamakan kemudahan memilih menu, varian/topping, input pembayaran tunai dengan tombol cepat, serta verifikasi kilat pembayaran QRIS menggunakan kamera tanpa internet.
   * Menampilkan dan membagikan struk digital resmi yang sudah terintegrasi bukti bayar.
   * Melakukan tutup shift/toko dan mengirimkan rekapitulasi harian ke WhatsApp Owner dengan satu tombol.
   * Tidak memiliki akses untuk mengubah harga produk atau menghapus riwayat tanpa otorisasi PIN.
2. **Pemilik Toko (Owner / Manager)**:
   * Memantau omzet harian dari rumah melalui pesan ringkasan otomatis WhatsApp yang dikirim kasir setiap malam.
   * Mengetahui secara presisi berapa uang fisik tunai yang harus disetor kasir vs berapa dana yang masuk ke rekening bank lewat QRIS.
   * Mengunduh rekapitulasi pembukuan bulanan format Excel multi-sheet (`.xlsx`) untuk menghitung laba bersih dan perencanaan belanja bahan baku.

---

## 4. Fitur Utama & Kebutuhan Fungsional (Functional Requirements)

### A. Katalog Produk & Varian Dinamis
* **Hierarki Kategori & Produk**:
  * Kategori: *Makanan Ringan, Minuman Segar, Minuman Boba, Kopi & Matcha, Roti & Keju*.
  * Produk terintegrasi: *Lumpia Ubi Ungu, Lumpia Celembu, Mojito Series, Milk Boba Series, Pure Matcha, Potato Korean Cheese Bread*.
* **Varian & Modifiers (Add-ons)**:
  * Pilihan ukuran (*Regular / Large*).
  * Level gula (*Normal Sugar / Less Sugar 50% / No Sugar*).
  * Level es (*Normal Ice / Less Ice / No Ice*).
  * Topping ekstra (*Boba, Jelly, Keju Mozzarella* dengan penambahan harga otomatis).
* **Pencarian Cepat & Filter**:
  * Real-time search bar dengan pencarian nama menu atau SKU instan.
  * Tab kategori responsif dengan ikon visual.

### B. Kasir & Keranjang Belanja Cepat (Quick Cart)
* Penambahan item instan ke keranjang (1-tap).
* Penyesuaian kuantitas (`+`, `-`, atau input numerik langsung).
* Catatan khusus per pesanan item (contoh: *"bungkus terpisah"*, *"less sweet"*).
* Perhitungan otomatis:
  * Subtotal item & modifiers.
  * Diskon (nominal Rp atau persentase %).
  * Pembulatan harga otomatis ke kelipatan terdekat (misal: pembulatan Rp 100).

### C. Pembayaran Tunai & Verifikasi QRIS Offline (Anti-Fraud OCR Scanner)
* **Metode Tunai (Cash)**:
  * Tombol nominal pas (*Exact Amount*).
  * Tombol pecahan uang umum Indonesia (Rp 10.000, Rp 20.000, Rp 50.000, Rp 100.000).
  * Kalkulasi kembalian *real-time* saat kasir mengetik nominal uang yang diterima.
  * Validasi penguncian tombol konfirmasi jika uang tunai masih kurang.

* **Metode QRIS & Verifikator Kamera Offline (Local OCR Scanner)**:
  * Kasir menampilkan stiker QRIS outlet kepada pembeli.
  * Saat pembeli menunjukkan layar bukti bayar di HP mereka, kasir menekan tombol **"Verifikasi Scan Bukti Bayar"** di aplikasi POS.
  * Kamera kasir membaca layar HP pembeli secara **100% Offline** (menggunakan *Google ML Kit Text Recognition on-device* tanpa internet).
  * **Aturan Validasi Ketat Anti-Manipulasi**:
    1. **Validasi Tanggal & Jam Ketat (*Strict Timestamp Window*)**:
       - Tanggal transaksi pada bukti bayar **wajib sama dengan hari ini**.
       - Jam transaksi pada bukti bayar wajib berada dalam rentang toleransi waktu saat kasir melakukan scan (maksimal $\pm 5$ hingga $\pm 10$ menit dari jam perangkat kasir). Jika pembeli menunjukkan foto lama/screenshot kemarin, sistem langsung menolak: *"Bukti transfer kedaluwarsa atau tidak valid!"*.
    2. **Validasi Kesesuaian Nominal (*Exact Amount Match*)**:
       - Nilai nominal uang pada bukti bayar wajib sama persis dengan total tagihan pesanan (contoh: Rp 38.500). Jika tidak cocok, sistem menolak: *"Nominal tidak sesuai! Tagihan: Rp 38.500"*.
    3. **Validasi Kata Kunci Status (*Keyword Detection*)**:
       - Wajib mendeteksi kata penanda sukses: *"Berhasil"*, *"Transaksi Berhasil"*, *"Payment Successful"*, atau *"Selesai"*.
    4. **Ekstraksi Otomatis Nomor Referensi (RRN)**:
       - Membaca nomor referensi unik bank (12 digit angka) dan nama aplikasi bank/e-wallet pengirim.
  * **Penyimpanan Snapshot & Hasil Scan**:
    - Sistem otomatis menyimpan foto bukti bayar terkompresi (~50KB) ke storage lokal perangkat (`/qris_proofs/{order_id}.jpg`).
    - Nomor referensi, waktu transaksi hasil scan, dan path foto otomatis dihubungkan ke record `Order` di SQLite.
    - Begitu verifikasi sukses, aplikasi bersuara notifikasi *"Tring! QRIS Terverifikasi"*, layar berubah hijau, dan langsung menyelesaikan pesanan.

### D. Struk Digital Terintegrasi Bukti Bayar (Integrated Digital Receipt)
* **Format Struk Lengkap**:
  * Header: Nama Toko, Alamat, No. WhatsApp, Kasir.
  * Detail Menu: Item, Varian/Modifier, Qty, Harga, Subtotal, Diskon.
  * Info Pembayaran:
    * Jika Tunai: Nominal Tunai, Uang Kembalian.
    * Jika QRIS: Tanda *"LUNAS QRIS (Terverifikasi)"*, Nomor Referensi (RRN), Jam Pembayaran terekstrak dari scan.
  * Tombol Audit: **"Lihat Foto Bukti Bayar"** langsung di dalam riwayat struk untuk melihat foto asli yang di-scan kasir.
* **Fitur Berbagi Instan (Share Plus)**:
  * Tombol berbagi struk dalam format teks rapi atau gambar struk via WhatsApp ke nomor pelanggan.

### E. Laporan Tutup Toko Otomatis via WhatsApp ke Owner (End-of-Day WhatsApp Daily Recap)
Fitur unggulan untuk memudahkan Owner memantau gerai dari rumah tanpa perlu datang ke lokasi setiap malam:
* **Alur Tutup Shift / Tutup Toko Kasir**:
  1. Kasir membuka menu **"Tutup Shift / Tutup Toko"** di akhir jam operasional.
  2. Kasir memasukkan jumlah uang fisik yang ada di laci kas (*Physical Cash Count*).
  3. Sistem menghitung secara otomatis:
     * **Total Transaksi & Total Omzet Hari Ini**.
     * **Pemisahan Metode Bayar**:
       - *Uang Tunai (Cash)*: Total uang tunai yang **wajib disetor fisik** oleh kasir ke Owner.
       - *Uang QRIS (Bank)*: Total dana non-tunai yang **langsung masuk ke rekening bank Owner**.
     * **Top 3-5 Menu Terlaris**: Produk dengan penjualan tertinggi hari ini beserta porsi terjual.
     * **Rekonsiliasi Kas Laci (Cash Drawer)**: Modal awal + Penjualan tunai - Pengeluaran kas kecil operasional (beli es batu/plastik/gas) vs Uang fisik di laci (Status: *PAS*, *LEBIH*, atau *SELISIH KURANG*).
* **Pengiriman 1-Klik ke WhatsApp Owner**:
  * Muncul tombol besar: **"Kirim Laporan ke WhatsApp Owner"**.
  * Aplikasi merangkai pesan teks terformat rapi (dengan emoji, huruf tebal WhatsApp, dan rincian lengkap) dan langsung membuka aplikasi WhatsApp yang tertuju ke nomor WhatsApp Owner yang tersimpan di pengaturan.
  * Kasir tinggal menekan tombol *Send* di WhatsApp.

### F. Ekspor Laporan Bulanan & Harian Multi-Sheet Excel (.xlsx)
* **Fitur Ekspor 1-Klik ke Spreadsheet**:
  * Dihasilkan 100% secara lokal menggunakan package `excel` tanpa membutuhkan internet atau server.
  * File dapat langsung dibagikan ke WhatsApp atau Google Drive Owner melalui `share_plus`.
* **Struktur 3 Sheet Lengkap**:
  1. **Sheet 1 — Ringkasan Harian (*Daily Summary*)**:
     * Kolom: Tanggal, Jumlah Transaksi, Total Omzet, Porsi Tunai, Porsi QRIS, Total Diskon.
  2. **Sheet 2 — Rincian Seluruh Transaksi (*Transaction Log*)**:
     * Kolom: Order ID, Waktu/Jam, Kasir, Total Belanja, Metode Bayar (Tunai / QRIS), No. Referensi QRIS (RRN), Status (Paid/Void).
  3. **Sheet 3 — Laporan Performa Menu (*Product Performance*)**:
     * Kolom: Kategori, Nama Menu, Total Kuantitas Terjual, Total Pendapatan per Menu (sangat berguna untuk perencanaan stok dan belanja bahan baku).

### G. Mesin Offline-First & Sinkronisasi Cloud CRDT (`CrdtCloudEngine`)
* **Penyimpanan SQLite Lokal**:
  * Seluruh data pesanan, shift, dan log verifikasi tersimpan di SQLite lokal perangkat kasir (latensi 0ms).
* **Format ID Terdistribusi**:
  * Menggunakan **UUID v4** untuk seluruh record (`order_id`, `item_id`, `product_id`, `shift_id`).
* **Sync Queue ke Cloud Server**:
  * Transaksi lokal dicatat ke tabel antrean mutasi (`crdt_mutations`) dengan penanda waktu monotonik (*Hybrid Logical Clock* / HLC).
  * Ketika koneksi internet tersedia, sistem mengunggah antrean mutasi dan metadata transaksi ke Cloud Server di latar belakang.
  * Resolusi konflik *Last-Write-Wins* (LWW) berbasis HLC.

### H. Riwayat Transaksi & Pembatalan (Void)
* Menampilkan daftar transaksi berdasarkan tanggal dan status (Berhasil / Void).
* Setiap riwayat transaksi QRIS menampilkan thumbnail foto bukti scan dan nomor referensinya.
* Otorisasi Void pesanan dengan verifikasi PIN otorisasi Pemilik Toko serta pencatatan alasan pembatalan.

---

## 5. Kebutuhan Non-Fungsional (Non-Functional Requirements)
1. **Performa & Responsivitas**:
   * Operasi kasir 100% offline tanpa hambatan jaringan.
   * Proses verifikasi OCR bukti bayar pada kamera kasir < 1.5 detik (menggunakan on-device model).
   * Pembuatan pesan WhatsApp dan file spreadsheet Excel < 500ms.
2. **Desain Adaptif Multi-Form Factor**:
   * **Smartphone (Portrait)**: Layout vertikal optimal untuk kasir satu tangan, dengan tombol cepat scan bukti bayar dan tutup toko.
   * **Tablet (Landscape)**: Tampilan dua kolom (*Master-Detail Split Screen*): Katalog Menu di sisi kiri (60%) dan Keranjang Belanja & Panel Pembayaran tetap di sisi kanan (40%).
3. **Ketahanan Data & Privasi**:
   * Transaksi SQLite atomik (`db.transaction`), data tidak hilang meski aplikasi tertutup mendadak.
   * Foto bukti bayar disimpan di internal app sandbox, aman dan terindeks dengan `order_id`.

---

## 6. Model Data Inti (Data Model Blueprint)
* `StoreSettings` (
    `id` TEXT PRIMARY KEY,
    `store_name` TEXT,
    `address` TEXT,
    `phone_number` TEXT,
    `owner_whatsapp_number` TEXT,
    `owner_pin_hash` TEXT
  )
* `Category` (`id` TEXT PRIMARY KEY, `name` TEXT, `icon` TEXT, `sort_order` INTEGER, `updated_at` INTEGER, `is_deleted` INTEGER)
* `Product` (`id` TEXT PRIMARY KEY, `category_id` TEXT, `name` TEXT, `base_price` INTEGER, `sku` TEXT, `image_url` TEXT, `is_available` INTEGER, `updated_at` INTEGER, `is_deleted` INTEGER)
* `ProductModifier` (`id` TEXT PRIMARY KEY, `product_id` TEXT, `name` TEXT, `extra_price` INTEGER, `group_name` TEXT, `updated_at` INTEGER)
* `Order` (
    `id` TEXT PRIMARY KEY, 
    `order_number` TEXT, 
    `shift_id` TEXT,
    `subtotal` INTEGER, 
    `discount_amount` INTEGER, 
    `tax_amount` INTEGER, 
    `total_amount` INTEGER, 
    `payment_method` TEXT, 
    `cash_tendered` INTEGER, 
    `change_due` INTEGER, 
    `qris_reference_no` TEXT, 
    `qris_scanned_timestamp` TEXT, 
    `qris_proof_image_path` TEXT, 
    `status` TEXT, 
    `created_at` INTEGER, 
    `hlc_timestamp` TEXT
  )
* `OrderItem` (`id` TEXT PRIMARY KEY, `order_id` TEXT, `product_id` TEXT, `product_name` TEXT, `unit_price` INTEGER, `quantity` INTEGER, `subtotal` INTEGER, `notes` TEXT, `selected_modifiers_json` TEXT)
* `Shift` (
    `id` TEXT PRIMARY KEY,
    `cashier_name` TEXT,
    `opened_at` INTEGER,
    `closed_at` INTEGER,
    `starting_cash` INTEGER,
    `actual_cash` INTEGER,
    `system_cash` INTEGER,
    `cash_in` INTEGER,
    `cash_out` INTEGER,
    `status` TEXT
  )
* `CashMovement` (
    `id` TEXT PRIMARY KEY,
    `shift_id` TEXT,
    `type` TEXT, 
    `amount` INTEGER,
    `notes` TEXT,
    `created_at` INTEGER
  )
* `CrdtMutation` (`id` TEXT PRIMARY KEY, `table_name` TEXT, `record_id` TEXT, `action` TEXT, `payload_json` TEXT, `hlc_timestamp` TEXT, `is_synced` INTEGER)

---

## 7. Roadmap Peluncuran

* **Fase 1 (MVP — Kasir Mandiri, Struk Digital, OCR QRIS, Rekap WhatsApp & Excel)**:
  * Katalog menu F&B lengkap dengan varian/topping.
  * Keranjang kasir reaktif & kalkulator kembalian tunai.
  * Pembayaran Tunai & QRIS Statis dengan **Offline OCR Camera Verification**.
  * Validasi ketat anti-fraud: Cek tanggal hari ini, jam transaksi toleransi $\pm 10$ menit, dan kecocokan nominal persis.
  * Penyimpanan foto bukti bayar lokal yang terhubung ke Struk Digital.
  * **Laporan Tutup Toko Otomatis ke WhatsApp Owner** dengan pemisahan Uang Tunai (wajib setor) vs QRIS (rekening) serta Menu Terlaris.
  * **Ekspor Laporan Excel Multi-Sheet (.xlsx)** untuk pembukuan bulanan.
  * Penyimpanan SQLite lokal dengan UUID & transaksi atomik.
  * Tampilan responsif (Smartphone Portrait & Tablet Landscape).

* **Fase 2 (Manajemen Shift Kasir & Hardware Printer)**:
  * Manajemen Shift Kasir Mendalam (Pencatatan pengeluaran kas kecil darurat / cash out).
  * Otorisasi Void pesanan dengan PIN Pemilik.
  * Integrasi driver Bluetooth Thermal Printer (ESC/POS 58mm/80mm) untuk cetak struk fisik kertas.

* **Fase 3 (Cloud Sync & Multi-Store Dashboard)**:
  * Sinkronisasi antrean CRDT ke Cloud Backend saat internet tersedia.
  * Upload batch foto bukti bayar ke cloud storage saat online.
  * Portal web analitik penjualan multi-cabang untuk pemilik toko.