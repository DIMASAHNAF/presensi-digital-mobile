# Presensi Siswa SMK Negeri 1 Beringin (Mobile App)

Aplikasi mobile presensi siswa native berbasis **Flutter** dengan integrasi biometrik wajah **ArcFace 512-D**, satelit GPS **Geofencing 6-titik Polygon**, dan engine backend **Golang Microservice**.

---

## 🏗 Arsitektur Sistem

- **Aplikasi Siswa**: Flutter (Android & iOS)
- **High-Performance API**: Golang microservice (Gin + GORM + JWT Auth) port `8081` (tersedia di `https://presensi.smknegeri1beringin.sch.id/api/v1/`)
- **Face AI Biometric**: Python FastAPI (ArcFace 512-D ONNX + YuNet + MiniFASNet) port `8005`
- **Panel Admin / Guru**: Laravel Web Admin di `/www/wwwroot/presensi.tiksmkn1beringin.my.id`
- **Shared Storage**: NFS `/mnt/nfs/data-presensi`
- **Shared Database**: MySQL `presensi-online`

---

## ⚡ Fitur Utama

1. **Biometrik Wajah Presisi Tinggi**:
   - Perekaman wajah via kamera depan (640x480).
   - Ekstraksi 512-D embedding via ArcFace ONNX.
   - Deteksi keaslian wajah (liveness anti-spoofing).
2. **Satelit Geofencing 6-Titik Polygon**:
   - Algoritma Ray-Casting Point-in-Polygon (bukan sekadar lingkaran radius kasar).
   - Anti-Mock Location / Fake GPS rejection.
   - Akurasi GPS maksimum 80 meter.
3. **Sinkronisasi Real-Time**:
   - Setiap scan berhasil langsung muncul di dashboard guru dan walikelas di panel web Laravel tanpa jeda.
4. **Notifikasi WhatsApp Orang Tua**:
   - Siswa terlambat otomatis dikirimi notifikasi WhatsApp via background goroutine.
5. **Modern UI / UX**:
   - Desain fintech-grade, Apple FaceID scanning HUD, typography Inter & Plus Jakarta Sans.

---

## 📱 Cara Menjalankan di Komputer / Laptop Lokal

### 1. Salin / Clone Project ke Komputer Anda
Anda dapat menyalin folder ini ke laptop menggunakan Git atau SCP / rsync / SFTP:

```bash
# Menggunakan rsync / scp dari terminal laptop Anda:
rsync -avz root@<IP_SERVER>:/www/wwwroot/presensi-mobile-app/ ./presensi-mobile-app/

# Atau melalui Git:
git clone ssh://root@<IP_SERVER>/www/wwwroot/presensi-mobile-app/.git
```

### 2. Buka di VS Code atau Android Studio
Pastikan Flutter SDK sudah terpasang di komputer Anda (`flutter doctor`).

### 3. Install Dependensi
```bash
cd presensi-mobile-app
flutter pub get
```

### 4. Jalankan di Smartphone Fisik atau Emulator
Hubungkan smartphone Android Anda via kabel USB (aktifkan USB Debugging):
```bash
flutter run
```

### 5. Build APK Release untuk Dibagikan ke Siswa
```bash
flutter build apk --release
```
File APK siap instal akan berada di: `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔑 Endpoint API yang Digunakan
Base URL: `https://presensi.smknegeri1beringin.sch.id/api/v1`

- `POST /auth/login` - Otentikasi NISN & Password (menghasilkan Bearer JWT)
- `GET /siswa/me` - Ambil profil siswa
- `GET /siswa/sesi-aktif` - Ambil data sesi mata pelajaran & polygon geofencing sekolah
- `POST /siswa/scan-wajah` - Kirim foto wajah & koordinat GPS untuk verifikasi
- `GET /siswa/riwayat` - Ambil riwayat presensi siswa

