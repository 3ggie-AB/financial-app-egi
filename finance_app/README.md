# FinanceKu 💰
Aplikasi manajemen keuangan pribadi berbasis Flutter

## Fitur Utama

### 📊 Dashboard
- Ringkasan saldo total semua rekening
- Pemasukan & pengeluaran bulanan
- Grafik pie chart pengeluaran per kategori
- Overview budget
- Transaksi terbaru

### 💳 Transaksi
- Tambah pengeluaran, pemasukan, dan transfer antar rekening
- Filter berdasarkan jenis, rekening, dan kategori
- Pencarian transaksi
- Catatan dan tag untuk setiap transaksi

### 🏦 Rekening
- Jenis: Tunai, Bank, Kartu Kredit, E-Wallet, Investasi
- Saldo otomatis terupdate saat transaksi
- Kustomisasi warna

### 🏷️ Kategori
- Kategori pengeluaran & pemasukan
- Warna kustom
- Default: Makanan, Transportasi, Belanja, dll.

### 🔖 Tag
- Label bebas untuk menandai transaksi
- Multi-tag per transaksi

### 📅 Budget
- Atur batas pengeluaran per kategori
- Progress bar visual
- Notifikasi saat melebihi budget

### ☁️ Backup & Restore
- **Google Drive**: Login dengan Google → Backup/Restore otomatis
- **JSON Lokal**: Export ke file JSON, import dari file JSON

---

## Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Setup Google Sign In (untuk Google Drive backup)

#### Android
1. Buat project di [Google Cloud Console](https://console.cloud.google.com)
2. Enable **Google Drive API** dan **Google Sign-In API**
3. Buat OAuth 2.0 Client ID untuk Android
4. Download `google-services.json` → taruh di `android/app/`
5. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
6. Update `android/build.gradle`:
   ```gradle
   classpath 'com.google.gms:google-services:4.3.15'
   ```

#### iOS
1. Buat OAuth Client ID untuk iOS
2. Download `GoogleService-Info.plist` → taruh di `ios/Runner/`
3. Tambahkan URL scheme ke `ios/Runner/Info.plist`

> ⚠️ Tanpa Google setup, backup JSON lokal tetap berfungsi penuh

### 3. Run
```bash
flutter run
```

---

## Struktur Proyek

```
lib/
├── main.dart                    # Entry point
├── models/
│   └── models.dart              # Account, Category, Tag, Transaction, Budget
├── services/
│   ├── database_service.dart    # SQLite CRUD
│   └── backup_service.dart      # Google Drive & JSON backup
├── providers/
│   ├── finance_provider.dart    # State management keuangan
│   └── theme_provider.dart      # Dark/light mode
├── utils/
│   └── app_theme.dart           # Theme & formatters
└── screens/
    ├── main_screen.dart         # Bottom nav wrapper
    ├── dashboard/               # Dashboard dengan chart
    ├── transactions/            # List & form transaksi
    ├── accounts/                # Kelola rekening
    ├── categories/              # Kelola kategori
    ├── tags/                    # Kelola tag
    ├── budgets/                 # Budget tracker
    ├── backup/                  # Backup UI
    └── more/                    # Menu lainnya
```

---

## Teknologi
- **Flutter** - UI framework
- **SQLite (sqflite)** - Database lokal
- **Provider** - State management
- **Google Sign In + Drive API** - Cloud backup
- **fl_chart** - Grafik & chart
- **intl** - Format mata uang & tanggal (IDR)

---

## Data Default

Saat pertama dijalankan, app otomatis membuat:
- 3 rekening: Dompet, BCA, GoPay
- 8 kategori pengeluaran
- 5 kategori pemasukan  
- 5 tag default
