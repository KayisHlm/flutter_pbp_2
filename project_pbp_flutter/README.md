# Project PBP Flutter - Aplikasi Pencatatan Hutang

Aplikasi mobile untuk mencatat dan mengelola hutang berbasis Flutter.

## Fitur Aplikasi

- **Halaman Home**: Menampilkan ringkasan total hutang dan daftar penghutang
- **Detail Hutang**: Menampilkan informasi detail hutang, riwayat pembayaran, dan status hutang
- **Detail User**: Menampilkan profil penghutang dan daftar hutangnya
- **Tambah Hutang**: Form untuk menambahkan hutang baru
- **Floating Action Button**: Tombol cepat untuk menambahkan hutang baru

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi dan routing
├── models/
│   ├── user.dart            # Model data user/penghutang
│   └── hutang.dart          # Model data hutang dan pembayaran
└── screens/
    ├── home_screen.dart     # Halaman utama dengan daftar penghutang
    ├── hutang_detail_screen.dart  # Halaman detail hutang
    ├── user_detail_screen.dart    # Halaman detail user/penghutang
    └── add_hutang_screen.dart     # Halaman tambah hutang baru
```

## Cara Menjalankan Aplikasi

1. **Install Flutter**: Pastikan Flutter sudah terinstall di komputer Anda

2. **Clone atau buat project**:
   ```bash
   cd project_pbp_flutter
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Jalankan aplikasi**:
   ```bash
   flutter run
   ```

## Fitur Detail

### Halaman Home
- Menampilkan total hutang secara keseluruhan
- Menampilkan jumlah penghutang
- List penghutang dengan jumlah hutang masing-masing
- Floating button untuk tambah hutang baru

### Halaman Detail Hutang
- Informasi lengkap hutang (deskripsi, jumlah, sisa, status)
- Informasi penghutang (nama, telepon, alamat)
- Tanggal jatuh tempo dengan indikator warna
- Riwayat pembayaran jika ada
- Tombol tambah pembayaran untuk hutang yang belum lunas

### Halaman Detail User
- Profil lengkap penghutang
- Ringkasan total hutang dan jumlah hutang
- Daftar semua hutang milik user tersebut
- Tombol tambah hutang baru untuk user tersebut

### Halaman Tambah Hutang
- Form lengkap untuk menambahkan hutang baru
- Pilih penghutang dari daftar yang tersedia
- Input deskripsi, jumlah, dan tanggal jatuh tempo
- Catatan opsional

## Teknologi yang Digunakan

- **Flutter**: Framework UI untuk membuat aplikasi mobile
- **Dart**: Bahasa pemrograman untuk Flutter
- **Intl**: Package untuk formatting mata uang dan tanggal dalam bahasa Indonesia

## Tampilan Aplikasi

Aplikasi ini memiliki desain modern dengan:
- Warna tema biru sebagai warna utama
- Card-based layout untuk informasi yang terstruktur
- Gradient background untuk header
- Responsive design yang menyesuaikan ukuran layar
- Floating action button untuk akses cepat

## Pengembangan Selanjutnya

Untuk pengembangan selanjutnya, aplikasi ini bisa ditambahkan dengan:
- Backend API untuk menyimpan data secara persisten
- Fitur autentikasi user
- Export data ke PDF atau Excel
- Notifikasi untuk hutang yang jatuh tempo
- Fitur cicilan dan perhitungan bunga
- Multi-bahasa support