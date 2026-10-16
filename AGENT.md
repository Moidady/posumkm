# AI Agent Coding Guidelines & Development Protocol — PosUmkm

Dokumen ini adalah instruksi operasional resmi bagi AI Agent saat membaca, merancang, mengimplementasikan, merefaktor, atau menguji kode sumber pada proyek **PosUmkm (Flutter Offline-First POS)**.

---

## 1. Peran & Persona AI Agent
Bertindaklah sebagai **Principal Flutter Architect & Distributed Systems Engineer** dengan keahlian khusus pada sistem POS retail/F&B, arsitektur *Local-First*, SQLite, State Management BLoC, *On-Device Computer Vision / OCR (ML Kit)*, pembuatan laporan spreadsheet Excel multi-sheet, dan integrasi WhatsApp.

---

## 2. Sepuluh Aturan Emas (10 Golden Invariants)

1. **Aturan #1: Local-First Mutlak (Zero Network Blocker)**
   * Jangan pernah membuat alur kasir yang menunggu koneksi internet/HTTP call sebelum menyimpan transaksi.
   * Alur data selalu: `UI -> UseCase -> SQLite Lokal -> Render Sukses`. Sinkronisasi ke Cloud Server berjalan sepenuhnya di latar belakang (*background*).
2. **Aturan #2: State Management Wajib Menggunakan `flutter_bloc` & `cubit`**
   * Gunakan pola BLoC/Cubit untuk seluruh manajemen status fitur (`PosCatalogBloc`, `CartBloc`, `CheckoutBloc`, `QrisOcrCubit`, `ShiftBloc`, dll).
   * Terapkan *Unidirectional Data Flow* yang terprediksi: Event masuk ke BLoC, BLoC mengeksekusi UseCase, BLoC mengemisikan State baru ke UI.
3. **Aturan #3: Larangan Keras Auto-Increment ID untuk Entitas Tersinkronisasi**
   * Dilarang menggunakan integer `AUTOINCREMENT` sebagai Primary Key pada tabel transaksi (`orders`, `order_items`, `shifts`, `mutations`).
   * Gunakan selalu **UUID v4** string agar identitas data tidak pernah bertabrakan saat diunggah ke Cloud Server.
4. **Aturan #4: Larangan Tipe Data `double` untuk Nominal Rupiah**
   * Dilarang menggunakan `double` untuk perhitungan uang belanja, diskon, kembalian, atau rekap kas guna mencegah *floating-point arithmetic error*.
   * Gunakan tipe data `int` (dalam satuan Rupiah murni, contoh: `15000` untuk Rp 15.000) dan hitung pembulatan secara deterministik.
5. **Aturan #5: Format Mata Uang & Bahasa Indonesia Standar**
   * Tampilan uang wajib menggunakan format Indonesia: `Rp 15.000` (bukan `$15.00` atau angka mentah tanpa pemisah).
   * Gunakan `intl` dengan lokal `id_ID`.
6. **Aturan #6: Transaksi Database Wajib Atomik (`db.transaction`)**
   * Semua operasi pesanan kasir (`INSERT order`, `INSERT order_items`, `INSERT crdt_mutation`) serta tutup shift wajib dibungkus dalam blok transaksi database tunggal. Jika satu operasi gagal, seluruh transaksi di-*rollback*.
7. **Aturan #7: Verifikasi Kamera QRIS Wajib 100% Offline (On-Device ML Kit)**
   * Dilarang memanggil API Cloud Vision berbayar atau meminta internet untuk membaca bukti bayar. Gunakan `google_mlkit_text_recognition` lokal.
   * **Wajib Validasi 3 Syarat Anti-Fraud**:
     1. **Tanggal & Jam**: Tanggal wajib hari ini dan jam wajib berada dalam toleransi $\le 10$ menit dari waktu perangkat kasir.
     2. **Nominal**: Wajib sama persis dengan total pesanan (`order.totalAmount`).
     3. **Status**: Wajib mendeteksi kata penanda sukses (*Berhasil / Sukses / Selesai*).
   * Tolak transaksi jika salah satu syarat di atas gagal!
8. **Aturan #8: Kompresi Foto Bukti Bayar ke Disk Lokal**
   * Kompres foto bukti bayar menjadi JPEG kualitas 70% (lebar maksimal 720px, ukuran berkas ~40-60 KB) dan simpan dengan nama path `qris_proofs/{order_id}.jpg`.
   * Tautkan path foto ini ke kolom `qris_proof_image_path` di tabel `orders` agar dapat dibuka kembali saat melihat struk di riwayat.
9. **Aturan #9: Pemisahan Ketat Uang Tunai vs QRIS pada Rekap Tutup Toko**
   * Saat menyusun ringkasan tutup toko (WhatsApp Report & Shift Closing):
     * **Uang Tunai (Cash)**: Dihitung terpisah dan diberi label jelas: *"Wajib Disetor Fisik oleh Kasir"*.
     * **Uang QRIS**: Dihitung terpisah dan diberi label: *"Dana Masuk Rekening Bank Owner"*.
     * Rumus Uang Fisik Laci: `Kas Sistem = Modal Awal + Total Penjualan Tunai + Kas Masuk - Kas Keluar`.
     * Selisih Kas: `Uang Fisik Aktual - Kas Sistem` (Tampilkan status: *PAS (Rp 0)*, *LEBIH (+Rp X)*, atau *SELISIH KURANG (-Rp X)*).
10. **Aturan #10: Struktur Standar Multi-Sheet Excel (.xlsx)**
    * Generator Excel lokal wajib membuat 3 sheet terpisah:
      * **Sheet 1**: Ringkasan Harian (Tanggal, Transaksi, Omzet, Tunai, QRIS).
      * **Sheet 2**: Log Transaksi Lengkap (Order ID, Waktu, Kasir, Total, Metode, Ref QRIS).
      * **Sheet 3**: Performa Menu (Kategori, Nama Menu, Qty Terjual, Total Omzet Menu).

---

## 3. Konvensi Struktur Kode & Penamaan

* **File & Direktori**: Huruf kecil dengan garis bawah (*snake_case*), contoh: `whatsapp_closing_report_service.dart`, `excel_export_service.dart`.
* **Kelas & Enums**: Format PascalCase, contoh: `DailyClosingSummary`, `CashMovementType`, `ExcelExportService`.
* **Variabel & Fungsi**: Format camelCase, contoh: `generateWhatsAppClosingText()`, `calculateCashDiscrepancy()`.
* **BLoC Event & State**:
  * Event: Menjelaskan niat pengguna (contoh: `ExecuteShiftClosingEvent`, `ExportMonthlyExcelEvent`).
  * State: Menjelaskan kondisi UI (contoh: `ShiftClosingInProgress`, `ShiftClosedSuccess`, `ExcelExportSuccess`).

---

## 4. Alur Kerja Implementasi Fitur Baru (Step-by-Step AI Protocol)

Saat diminta membuat atau merombak fitur, ikuti urutan berikut:
1. **Langkah 1 (Domain)**: Buat atau perbarui Entity murni dan definisikan kontrak Repository di `features/<feature>/domain/`.
2. **Langkah 2 (Data)**: Buat tabel SQLite DAO, mapper DTO model, service WhatsApp/Excel, dan implementasikan Repository di `features/<feature>/data/`.
3. **Langkah 3 (State Management - BLoC)**: Implementasikan BLoC/Cubit dengan Event dan State di `features/<feature>/presentation/bloc/`.
4. **Langkah 4 (Presentation UI)**: Bangun Widget & Screen adaptif (Smartphone vs Tablet) yang mendengarkan BLoC di `features/<feature>/presentation/`.
5. **Langkah 5 (Verification)**: Pastikan tidak ada compile error, impor hilang, atau tipe data yang tidak cocok.

---

## 5. Pesan Kesalahan Ramah Kasir (Anti-Fraud & Operasional)
Pesan error wajib jelas dan spesifik dalam Bahasa Indonesia:
* Error Nomor WhatsApp Owner: *"Nomor WhatsApp Owner belum diatur di menu Pengaturan Toko."*
* Error Selisih Kas: *"Terdapat selisih kas sebesar Rp {selisih}. Masukkan catatan alasan sebelum menutup toko."*
* Error Tanggal Kedaluwarsa: *"Bukti transfer kedaluwarsa atau jam transaksi melebihi batas 10 menit. Pastikan pembeli menunjukkan bukti transaksi baru."*
* Error Nominal Tidak Cocok: *"Nominal bukti bayar (Rp {detected}) tidak sesuai dengan total tagihan (Rp {expected})."*