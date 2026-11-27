---
name: presensi
description: Use when developing, auditing, debugging, extending, or maintaining the Presensi SMKN 1 Beringin digital attendance ecosystem (Flutter mobile, Rust Axum API, Laravel Web & Kiosk, Python Face AI, OpenWA/WhatsApp, database schema, or attendance verification rules).
---

# Presensi SMKN 1 Beringin — Architecture & Domain Guide

## 1. System Topology & Architecture

Presensi SMKN 1 Beringin is a high-performance, multi-tier attendance ecosystem serving students (*Siswa*), teachers (*Guru*), school administrators, and parents (*Wali Murid*).

```
                      +------------------------------------------+
                      |         Flutter Mobile App (v2.1.2)      |
                      |     Android (.apk)  /  iOS (.ipa)        |
                      +-------------------+----------------------+
                                          |
                                          | HTTPS / REST (JWT)
                                          v
                      +------------------------------------------+
                      |       Rust Axum API (:8088)              |
                      |   High-concurrency mobile backend        |
                      |   SQLx Connection Pool + Redis Cache     |
                      +-----+---------------------+--------------+
                            |                     |
           REST (/identify) |                     | SQL Queries
                            v                     v
+-----------------------------+         +-------------------------------+
|   Python Face AI (:8005)    |         |        MySQL Database         |
|  FastAPI + InsightFace      |         |      Database: `presensi`     |
|  ArcFace 512D + YuNet       |         |   Tables: presensi, siswa,    |
|  MiniFASNet Liveness        |         |   guru, users, jam_kerja, etc |
+-----------------------------+         +---------------+---------------+
                            ^                           ^
                            | REST                      | SQL / Eloquent
+---------------------------+--+                        |
|    Laravel 12 Web App        |                        |
|  - Kiosk Mode Attendance     +------------------------+
|  - Face Enrollment           |
|  - Admin & Teacher Dashboard |
|  - Livewire 3 + Alpine.js    |
+--------------+---------------+
               |
               v Dispatch Message
+-------------------------------+
|     OpenWA Gateway (:2785)    |
|   WhatsApp notification bot   |
|   (Fallback: Fonnte API)      |
+-------------------------------+
```

### Core Subsystems & Service Directories
| Subsystem | Directory / Repo | Stack | Port / Service |
|---|---|---|---|
| **Web & Admin** | `/www/wwwroot/presensi.tiksmkn1beringin.my.id` | Laravel 12, PHP 8.2, Livewire 3, Alpine.js, Tailwind | Nginx (:80/:443) |
| **Face AI** | `/www/wwwroot/presensi.tiksmkn1beringin.my.id/python-backend` | Python 3.10+, FastAPI, OpenCV, ONNX Runtime, InsightFace | Port 8005 (PM2 `face-api`) |
| **Mobile API** | `/www/wwwroot/presensi-rust-api` | Rust 1.80+, Axum v2, SQLx, Redis, JWT | Port 8088 (`systemd presensi-rust`) |
| **Mobile App** | `/www/wwwroot/presensi-mobile-app` | Flutter 3.24+, Dart, Riverpod, Rust FFI, Android + iOS | Mobile Client (v2.1.2+12) |
| **WhatsApp Bot**| `/www/wwwroot/presensi.tiksmkn1beringin.my.id/openwa-service` | Node.js, @open-wa/wa-automate | Port 2785 (PM2 `openwa`) |
| **Legacy API** | `/www/wwwroot/presensi-go-api` | Go 1.22+, Gin (Legacy reference) | Port 8080 (Standby) |
| **Shared Storage**| `/mnt/nfs/data-presensi` | NFS Mount (Photos, Docs, Face Embeddings) | Filesystem |

---

## 2. Core Invariants & Attendance Validation Flow

### Triple-Lock Security Verification
An attendance record is valid **ONLY** when passing three mandatory security gates:

1. **Biometric Face Verification (Gate 1)**:
   - **Embedding**: ArcFace 512-dimensional vector.
   - **Distance Metric**: Cosine Similarity.
   - **Thresholds**:
     - Siswa: Cosine similarity $\ge 0.42$ (or cosine distance $\le 0.58$).
     - Guru: Cosine similarity $\ge 0.40$ (or cosine distance $\le 0.60$).
   - **Liveness / Anti-Spoofing**: MiniFASNet score $\ge 0.70$ (rejects printed photos, screens, video replay).
2. **Geolocation & Geofencing (Gate 2)**:
   - **Haversine Distance**: $\le$ school radius setting (typically 50m with a 5m GPS margin).
   - **Polygon Ray-Casting**: Latitude & Longitude must fall strictly within the SMKN 1 Beringin cadastral boundary polygon.
   - **Anti-Mock Location**: Native Android/iOS check detecting mocked GPS providers or developer mock modes (`id.sch.smknegeri1beringin.presensi/mock_location`).
3. **Network Whitelist (Gate 3)**:
   - When configured for internal school check-in, client IP or Access Point BSSID must match MikroTik WiFi CIDR whitelist (`10.10.x.x`).

### Idempotency & Database Concurrency
- Multiple mobile check-in attempts within seconds (e.g. rapid taps or network retries) must **never** create duplicate rows.
- Table `presensi` enforces unique key `(tanggal, siswa_id)` or `(tanggal, user_id)`.
- All database write queries must use:
  ```sql
  INSERT INTO presensi (siswa_id, tanggal, jam_masuk, foto_masuk, status, lokasi_masuk)
  VALUES (?, ?, ?, ?, ?, ?)
  ON DUPLICATE KEY UPDATE
    jam_masuk = IF(jam_masuk IS NULL, VALUES(jam_masuk), jam_masuk),
    foto_masuk = IF(foto_masuk IS NULL, VALUES(foto_masuk), foto_masuk),
    status = IF(status = 'alpa', VALUES(status), status);
  ```
- Real-time Redis counters (`hadir_count_{tanggal}_{kelas_id}`) are incremented using atomic `INCR` operations.

### Attendance Shifts & State Transitions
- **Pagi (Check-in Masuk)**:
  - `06:00 - 07:30 WIB`: **Tepat Waktu** (On-time)
  - `07:31 - 08:30 WIB`: **Terlambat** (Late with minutes tracked)
  - After `08:30 WIB`: Flagged as Late (Major) or blocked depending on school policy.
- **Sore (Check-out Pulang)**:
  - `15:00 - 17:00 WIB`: **Pulang Standar**
  - Before `15:00 WIB`: **Pulang Cepat** (Requires teacher permission).
- **Excused**:
  - `Izin` (Permit): Requires documented reason + optional uploaded letter.
  - `Sakit` (Sick): Requires doctor's note uploaded to `/mnt/nfs/data-presensi/surat/`.
- **Auto-Alpa Cron**:
  - Daily scheduled task runs at `10:00 WIB` marking all enrolled students without check-in/permit as `alpa`.

---

## 3. Strict Security Rules & Audit Invariants

When working anywhere in this codebase, enforce these non-negotiable security requirements:

1. **Authentication Integrity**:
   - **NEVER** allow login bypass or blank password check when `password_changed_at IS NULL`. Always authenticate against the designated initial password (e.g., student NISN or teacher default password).
   - In `presensi-rust-api/src/handlers/auth.rs`, password update must verify the caller's authorized claims and enforce current password verification.
2. **Device Binding**:
   - Mobile logins must validate `device_id` against the registered student record. If mismatched, require administrative reset to prevent account sharing / "joki presensi".
3. **Face AI API Contract**:
   - Python backend endpoints must remain strictly synchronized with Rust Axum and Laravel callers:
     - `POST /identify-multi` : Face identification for Kiosk / mobile multi-candidate.
     - `POST /candidates/upsert` : Upsert candidate face embeddings.
     - `POST /check-duplicate` : Anti-duplicate enrollment verification.
4. **Blade & Frontend Sanitization**:
   - Never inject unescaped raw JSON into DOM scripts (`{!! json_encode(...) !!}`). Always use `@json(...)` or `data-*` attributes with proper HTML escaping to prevent Stored XSS.
5. **Photo File Storage & Privacy**:
   - Photo file paths follow the standard: `/mnt/nfs/data-presensi/{YYYY}/{MM}/{DD}/{nisn|nip}_{timestamp}.jpg`.
   - Never expose raw server filesystem paths to clients; serve through authenticated stream endpoints.

---

## 4. Operational Runbooks & Commands

### Service Management
```bash
# Rust Axum Mobile API (:8088)
systemctl status presensi-rust
systemctl restart presensi-rust
journalctl -u presensi-rust -f -n 50

# Python Face AI (:8005)
pm2 status face-api
pm2 restart face-api
pm2 logs face-api --lines 50

# WhatsApp OpenWA Daemon (:2785)
pm2 status openwa
pm2 restart openwa
pm2 logs openwa --lines 50

# Laravel Web App (:80 / :443)
cd /www/wwwroot/presensi.tiksmkn1beringin.my.id
php artisan queue:restart
php artisan cache:clear
php artisan config:cache
```

### Health Check Endpoints
```bash
# Rust API
curl -s http://127.0.0.1:8088/api/v1/health | jq .

# Python Face AI
curl -s http://127.0.0.1:8005/health | jq .

# OpenWA WhatsApp Service
curl -s http://127.0.0.1:2785/health | jq .
```

### Mobile Build & Release
- **Android APK**:
  ```bash
  cd /www/wwwroot/presensi-mobile-app
  flutter build apk --release --split-per-abi
  # Output: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
  ```
- **iOS IPA (Automated CI/CD via GitHub Actions)**:
  - Commit & push changes to `main` branch.
  - Workflow `.github/workflows/build-ios-ipa.yml` runs on `macos-latest`, compiles Flutter iOS release, builds unsigned `.ipa`, and attaches it as an artifact.
  - Published location for download: `/www/wwwroot/presensi.tiksmkn1beringin.my.id/public/download/presensi-smkn1beringin-ios.ipa`.
