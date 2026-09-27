# Homix Mobile App

Flutter client for customers, shop owners, technicians, and admins.

## Run locally

```powershell
cd mobile
flutter pub get
flutter run -d chrome
```

## Useful checks

```powershell
cd mobile
flutter analyze
flutter test
flutter build web
```

## Release setup

Android release builds now expect `android/key.properties` with your upload
keystore details. Start from `android/key.properties.example`, then point
`storeFile` at your real `.jks` or `.keystore` file before running
`flutter build appbundle` or `flutter build apk --release`.

## Backend base URL

- Android emulator uses `http://10.0.2.2:8000/api/v1`
- Web and desktop use `http://localhost:8000/api/v1`
