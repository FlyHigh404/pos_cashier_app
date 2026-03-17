# 📖 POS Cashier App - Local Setup Guide

Welcome to the Kasir POS App project! Follow these instructions to set up the environment, install dependencies, and run the application locally on your machine or emulator.

## 🛠 Prerequisites

Before starting, ensure you have the following installed on your system:
* **Flutter SDK:** [Install Guide](https://docs.flutter.dev/get-started/install)
* **Android Studio:** Required for the Android SDK and emulators.
* **Java Development Kit (JDK):** **Version 21 is strictly required.**
* **VS Code:** (Optional, but recommended) with the Flutter/Dart extensions.

## ⚙️ Step 1: Environment Setup

1. **Verify Flutter:** Open your terminal and run:
   ```bash
   flutter doctor
   ```
   Ensure there are no major red errors regarding the Android toolchain.
2. **Verify JDK 21:** Ensure your computer's `JAVA_HOME` environment variable is pointing directly to your JDK 21 installation folder.

## 🔐 Step 2: Add Configuration & Secret Files

For security reasons, API keys and Firebase configurations are not uploaded to the code repository. **You must obtain these two files from the lead developer before building the app.**

1. **Firebase Config:** Place the `google-services.json` file inside the `android/app/` directory.
2. **App Config:**
   Place the `config.json` file directly into the **root** folder of the project (the same folder level as `pubspec.yaml`). It should look like this:
   ```json
   {
     "GOOGLE_CLIENT_ID": "your-client-id-here"
   }
   ```

## 📦 Step 3: Install Dependencies

Open your terminal, navigate to the root folder of the project, and run:
```bash
flutter clean
flutter pub get
```

## 🚀 Step 4: Run the Application

Because this app uses securely injected environment variables, you **cannot** just press "Play" or use the standard `flutter run` command. You must pass the config file in the command line.

**To run the app on an attached phone or emulator (Debug Mode):**
```bash
flutter run --dart-define-from-file=config.json
```

**To build a release APK for an Android device:**
```bash
flutter build apk --release --dart-define-from-file=config.json
```
*The generated APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`*

---

### 💡 Troubleshooting

* **"Failed host lookup" / App Hanging:** If the app opens but gets stuck or throws network errors, ensure your testing device is connected to Wi-Fi. The app is designed to work offline, but requires an initial connection to authenticate.
* **"Gradle build daemon disappeared":** If the build crashes randomly, your computer may have run out of RAM. Close heavy applications (like Google Chrome tabs) and try building again.
* **"JDK Version Mismatch":** Ensure Android Studio's Gradle JDK is set to JDK 21 in the settings.