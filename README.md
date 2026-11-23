<div align="center">

  <!-- SVG HERO BANNER: MOBILE ATTENDANCE APP -->
  <svg width="100%" height="160" viewBox="0 0 900 160" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="mobileBgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#0284c7"/>
        <stop offset="40%" stop-color="#2563eb"/>
        <stop offset="100%" stop-color="#1e1b4b"/>
      </linearGradient>
      <linearGradient id="phoneGlow" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#38bdf8"/>
        <stop offset="100%" stop-color="#818cf8"/>
      </linearGradient>
      <filter id="mGlow" x="-20%" y="-20%" width="140%" height="140%">
        <feGaussianBlur stdDeviation="3" result="blur"/>
        <feComposite in="SourceGraphic" in2="blur" operator="over"/>
      </filter>
    </defs>
    <rect width="900" height="160" rx="16" fill="url(#mobileBgGrad)" stroke="#60a5fa" stroke-width="1.5"/>
    <!-- Phone Mockup Icon -->
    <g transform="translate(42, 24)">
      <rect x="0" y="0" width="60" height="112" rx="12" fill="#0f172a" stroke="#ffffff" stroke-width="2.5"/>
      <rect x="22" y="5" width="16" height="4" rx="2" fill="#475569"/>
      <!-- Inner Screen with Face Scan HUD -->
      <rect x="6" y="14" width="48" height="84" rx="6" fill="#1e293b"/>
      <circle cx="30" cy="48" r="16" fill="none" stroke="url(#phoneGlow)" stroke-width="1.5" stroke-dasharray="4 2"/>
      <circle cx="30" cy="48" r="8" fill="#38bdf8" fill-opacity="0.2"/>
      <path d="M22 36 L26 36 M34 36 L38 36 M22 60 L26 60 M34 60 L38 60" stroke="#38bdf8" stroke-width="2" stroke-linecap="round"/>
      <circle cx="30" cy="103" r="3" fill="#ffffff" fill-opacity="0.6"/>
    </g>
    <!-- Text Elements -->
    <text x="140" y="58" font-family="system-ui, -apple-system, sans-serif" font-size="28" font-weight="800" fill="#ffffff" letter-spacing="0.5">
      PRESENSI SISWA MOBILE <tspan fill="#38bdf8">v2.1.0+10</tspan>
    </text>
    <text x="140" y="86" font-family="system-ui, -apple-system, sans-serif" font-size="15" font-weight="500" fill="#bfdbfe">
      SMK Negeri 1 Beringin • Flutter Android Native Biometric Attendance
    </text>
    <text x="140" y="112" font-family="monospace" font-size="12" fill="#93c5fd">
      ArcFace 512-D ONNX | Dual Geofence 6-Point Polygon (5m Edge Margin) | Axum Rust API v2 Backend
    </text>
    <!-- Version Pill -->
    <g transform="translate(720, 28)">
      <rect width="145" height="30" rx="15" fill="#0369a1" stroke="#38bdf8" stroke-width="1.5"/>
      <circle cx="736" cy="43" r="5" fill="#38bdf8" filter="url(#mGlow)"/>
      <text x="750" y="48" font-family="monospace" font-size="11" font-weight="700" fill="#ffffff">RELEASE v2.1.0</text>
    </g>
  </svg>

  <p align="center" style="margin-top: 14px; margin-bottom: 14px;">
    <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24.5-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter 3.24"></a>
    <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart 3.5"></a>
    <a href="https://developer.android.com"><img src="https://img.shields.io/badge/Android-SDK_36_(Target_35)-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android SDK 36"></a>
    <a href="#"><img src="https://img.shields.io/badge/Backend-Rust_Axum_v2.0-F97316?style=for-the-badge&logo=rust&logoColor=white" alt="Rust Axum Backend"></a>
    <a href="#"><img src="https://img.shields.io/badge/Biometric-ArcFace_512--D-10B981?style=for-the-badge&logo=thealgorithms&logoColor=white" alt="ArcFace"></a>
    <a href="#"><img src="https://img.shields.io/badge/Geofence-Ray_Casting_5m_Margin-8B5CF6?style=for-the-badge&logo=googlemaps&logoColor=white" alt="Polygon Geofence"></a>
    <a href="#"><img src="https://img.shields.io/badge/Tests-28%2F28_Passed_(100%25)-059669?style=for-the-badge&logo=testinglibrary&logoColor=white" alt="Tests Passed"></a>
  </p>

  <p align="center">
    <strong>Aplikasi presensi mandiri native Android untuk siswa SMK Negeri 1 Beringin. Dilengkapi verifikasi biometrik wajah kamera depan, validasi polygon geofencing 6 titik dengan toleransi tepi 5 meter, fallback WiFi resmi sekolah di dalam gedung, offline queue terenkripsi, kunci hardware perangkat, dan tema visual modern khas iOS.</strong>
  </p>
</div>

---

## 📱 Arsitektur Ekosistem & Integrasi Backend

Aplikasi Android ini berkomunikasi langsung dengan backend berkecepatan tinggi **Presensi Rust API v2** (port `8088`), serta terintegrasi harmonis dengan sistem sekolah lainnya:

```
┌────────────────────────────────────────────────────────┐
│             Aplikasi Flutter Siswa Android             │
│            (Presensi, Profil, Jadwal, Riwayat)         │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST (Bearer JWT)
                            ▼
┌────────────────────────────────────────────────────────┐
│            Presensi Rust API v2 (Port 8088)            │
│       - Transaksional ON DUPLICATE KEY UPDATE          │
│       - Verifikasi Hardware Device ID                  │
│       - Toleransi Tepi Poligon 5m + WiFi Fallback      │
└──────────────┬──────────────────────────┬──────────────┘
               │                          │
               ▼                          ▼
┌──────────────────────────────┐ ┌───────────────────────┐
│     MySQL Database Pusat     │ │ Python face-api :8005 │
│ (Shared dgn Web Siswa iPhone │ │ - Check Duplicate     │
│   & Admin / Wali Kelas Web)  │ │ - Sync Kiosk Gerbang  │
└──────────────────────────────┘ └───────────────────────┘
```

> [!NOTE]
> Siswa pengguna iPhone/iOS, Guru, dan Wali Kelas tetap menggunakan portal Web resmi sekolah di `presensi.tiksmkn1beringin.my.id`. Seluruh data presensi tersinkronisasi 100% secara realtime di satu database MySQL bersama.

---

## ⚡ Fitur Utama & Keunggulan

1. **Biometrik Wajah 5-Pose & Liveness Detection**:
   - Perekaman wajah via kamera depan beresolusi tinggi dengan HUD panduan interaktif.
   - Ekstraksi 512-D embedding via ArcFace ONNX dengan threshold anti-joki `0.85`.
   - Sinkronisasi otomatis ke Kiosk Gerbang sekolah saat enroll atau registrasi berhasil.
2. **Dual-Satelit Geofencing & Fallback Jaringan**:
   - Algoritma Ray-Casting Point-in-Polygon 6-titik koordinat sekolah.
   - **Toleransi tepi 5.0 meter** agar siswa di batas gerbang tidak tertolak.
   - **Fallback WiFi Sekolah**: jika sinyal GPS lemah di dalam gedung/kelas, presensi tetap sah selama terhubung ke WiFi resmi sekolah (toleransi akurasi GPS hingga 150 meter).
   - Deteksi Anti-Mock Location (Fake GPS rejection).
3. **Kunci Hardware Perangkat (Device Locking)**:
   - Akun siswa terkunci pada satu hardware smartphone untuk mencegah titip absen.
   - Reset perangkat mandiri via WhatsApp OTP atau tombol **Reset Perangkat** oleh Admin di Web.
4. **Alur Izin & Sakit Tertib**:
   - Pengajuan izin dan sakit dikhususkan bagi Orang Tua dan Wali Kelas melalui portal Web. Siswa dapat memantau status izin/sakit mereka secara transparan pada kalender dan riwayat.
5. **Offline Attendance Queue**:
   - Penyimpanan antrean presensi lokal terenkripsi saat jaringan sekolah terputus sementara, otomatis tersinkronisasi saat koneksi pulih.
6. **UI/UX Modern iOS-Style**:
   - Desain clean bernuansa Apple Human Interface, transisi halus, haptic feedback, dan dukungan tema **Light Mode** (default) serta **Dark Mode**.

---

## 🛠 Cara Build & Verifikasi APK Release

### 1. Prasyarat Sistem
* Flutter SDK `3.24.5` atau terbaru
* Android SDK 36 (Platform 35, Build Tools 36.0.0)
* OpenJDK 17

### 2. Menjalankan Pengujian (Unit & Widget Tests)
```bash
flutter test
# Hasil: 28/28 tests passed (100% clean)
```

### 3. Kompilasi Release APK
```bash
flutter build apk --release
```

Hasil kompilasi siap dipasang pada perangkat siswa:
* **Lokasi APK**: `build/app/outputs/flutter-apk/app-release.apk`
* **Package ID**: `id.sch.smknegeri1beringin.presensi`
* **Version**: `2.1.0` (Build `10`)
* **Ukuran**: ~`64 MB`
* **Minimum Android**: Android 7.0+ (API level 24)

---

## 🔑 Endpoint API yang Digunakan (Rust API v2)

Base URL: `https://presensi.smknegeri1beringin.sch.id/api/v1`

| Method | Endpoint | Fungsi |
| :--- | :--- | :--- |
| `POST` | `/auth/login` | Login siswa, penguncian Device ID, & issue Bearer JWT |
| `POST` | `/auth/register` | Pendaftaran mandiri siswa baru & 5-pose face enroll |
| `GET` | `/siswa/dashboard-full` | Data sesi, ringkasan kehadiran mingguan/bulanan, jadwal mapel |
| `GET` | `/siswa/sesi-aktif` | Poligon geofencing sekolah & status sesi kelas |
| `POST` | `/presensi/scan` | Transaksi presensi scan wajah + GPS haversine/polygon |
| `POST` | `/siswa/enroll-face` | Perekaman wajah baru & sinkronisasi instan Kiosk Gerbang |
| `GET` | `/siswa/profile` | Profil siswa, avatar, dan banner |
| `POST` | `/siswa/profile/update` | Update foto profil/banner via multipart form data |
| `GET` | `/siswa/device/info` | Status perangkat terkunci |
| `POST` | `/siswa/device/reset` | Reset perangkat mandiri |
| `POST` | `/telemetry/offline-sync` | Sinkronisasi antrean absen offline |

---

<div align="center">
  <sub>Dikembangkan untuk SMK Negeri 1 Beringin • Bersih, Aman, &amp; Andal.</sub>
</div>
