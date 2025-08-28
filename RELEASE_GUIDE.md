# Panduan Release Aplikasi MasBro - Updated 2025

## 1. Update Icon Aplikasi dengan Logo MasBro

# mengubahnya pada pubspec.yaml

.\pada bagian flutter_launcher_icons: ...

````

## 2. Build Release APK
```bash
flutter clean
flutter pub get
flutter build apk --release
````

## 3. Lokasi Hasil Build

- **APK:** `android/app/build/outputs/flutter-apk/app-release.apk`
- **App Bundle:** `android/app/build/outputs/budle/release/app-release.aab`

## 4. Quick Commands

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

## 5. Upload ke Google Play Store

1. Build app bundle: `flutter build appbundle --release`
2. Upload file `.aab` ke [Google Play Console](https://play.google.com/console)

## 6. Troubleshooting

- Jika build gagal: `flutter clean && flutter pub get && flutter build apk --release`
- Jika scanning lama: Upload via Play Console web interface


# Cara Membersihkan build cache Gradle untuk Android
`cd android`
`./gradlew clean`
- Mengapa perlu: Gradle menyimpan cache hasil kompilasi sebelumnya yang bisa menyebabkan konflik dengan kode baru
- Dampak: Menghapus semua file intermediate build di direktori android/.gradle dan android/app/build
- Manfaat: Mencegah error "duplicate class" atau "method not found" saat build ulang

# Cara Deploy APK Kembali Setelah Clean Build
Build APK Debug (untuk testing):
`flutter build apk --debug`
- Lokasi hasil build: `android/app/build/outputs/apk/debug/app-debug.apk`

Build APK Release (untuk production):
`flutter build apk --release`
- Lokasi hasil build: `android/app/build/outputs/apk/release/app-release.apk`

Build APK Split (per ABI untuk ukuran lebih kecil):
`flutter build apk --release --split-per-abi`
- Lokasi hasil build: `android/app/build/outputs/apk/release/app-release-<abi>.`
contoh file:
app-arm64-v8a-release.apk
app-armeabi-v7a-release.apk
app-x86_64-release.apk

# Cara Install/Deploy APK:
Opsi 1 - Install langsung ke device:
`flutter install`
Opsi 2 - Install via ADB:
`adb install build/app/outputs/flutter-apk/app-release.apk`


# Tips Mengelola Penyimpanan:
Untuk Development:
- Build hanya saat perlu
`flutter build apk --debug --target-platform android-arm64`

Untuk Production:
- Gunakan appbundle untuk Play Store (lebih efisien)
`flutter build appbundle --release`

Clean Periodik:
- Clean hanya jika ada masalah build
`flutter clean && flutter pub get`

Clean semua cache Gradle:
`cd android`  
`./gradlew clean`