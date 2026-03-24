# بورصة الكويت — Native Android App

Native Flutter app for Kuwait Stock Exchange data. **No WebView. No browser. 100% native UI.**

## Features
- 📋 CIP & XBRL Disclosures (daily, previous session, company search)
- 👥 Insiders list (board, management, institutions)
- 🏦 Ownership structure & subsidiaries
- 📊 Financial reports (PDF links)
- 🏢 Company info (board, executives, auditors, contact)
- 💹 Stock prices via Yahoo Finance
- 📈 Kuwait & US market indexes (real-time)

## Build Options

### Option 1 — GitHub Actions (easiest, no local setup)
1. Push this folder to a GitHub repo
2. Go to **Actions** tab → **Build APK** → **Run workflow**
3. Download the APK from the **Artifacts** section when done (~5 min)

### Option 2 — Local build
```bash
# Install Flutter: https://flutter.dev/docs/get-started/install
flutter pub get
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Option 3 — Codemagic (free CI)
1. Sign up at codemagic.io
2. Connect your GitHub repo
3. Select Flutter → Build → Android APK
4. Download built APK

## Configuration
Edit `lib/services/api_service.dart`:
```dart
static const String gasUrl = 'YOUR_GAS_WEB_APP_URL_HERE';
```

## Architecture
```
lib/
├── main.dart              # App entry, theme (dark navy/gold, RTL, Cairo font)
├── models/models.dart     # All data models
├── services/api_service.dart  # GAS proxy + Yahoo Finance calls
├── widgets/app_widgets.dart   # Shared UI components
└── screens/
    ├── home_screen.dart       # Main grid menu
    ├── disclosure_screen.dart # CIP/XBRL daily/previous/search
    ├── search_screen.dart     # Company search for all modes
    ├── result_screen.dart     # Data display (insider/ownership/financial/compinfo/stocks)
    └── markets_screen.dart    # Indexes (KW + US) + stock price search
```

## Sheet mapping
| Mode | Sheet |
|------|-------|
| CIP Disclosures | Sheet1 |
| Insiders | Sheet2 |
| Ownership | Sheet3 |
| XBRL Disclosures | Sheet4 |
| Financial reports | Sheet5 |
| Company info | Sheet3 |
| Stock tickers | Sheet7 (col A = name, col B = ticker) |
