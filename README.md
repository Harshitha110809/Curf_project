# Flutter Appium E2E Automation Framework

An enterprise-grade, robust End-to-End automation framework for testing Flutter Android APKs using Node.js, Appium 2.x, Mocha, and the Page Object Model architecture.

## Features
- **Flutter Support**: Integrates `appium-flutter-driver` for native Flutter widget interaction (`byValueKey`, `byText`, `bySemanticsLabel`).
- **Reporting**: Generates multi-sheet Excel reports and HTML reports via Mochawesome.
- **Resilience**: Automatic screenshot and widget tree capture on test failure.
- **Gestures**: Reusable utility for common gestures (swipe, scroll, long press).
- **CI/CD Ready**: Fully configured GitHub Actions workflow for automated execution on macOS runners with hardware-accelerated Android Emulators.
- **AI-Assisted Testing Module**: A script to parse Flutter Render Trees and suggest test coverage.

## Prerequisites
- Node.js (v18+)
- Java JDK 17
- Android SDK & Emulator
- Appium 2.x (`npm i -g appium`)
- Appium Drivers:
  - `appium driver install uiautomator2`
  - `appium driver install flutter`

## Setup
1. Clone the repository.
2. Run `npm install` to install dependencies.
3. Place your target APK in the `app/` directory and name it `app-release.apk` (or update `config/capabilities.js`).
4. Start Appium server in a separate terminal: `appium`
5. Ensure an Android Emulator is running or a real device is connected.

## Directory Structure
- `config/`: Appium capabilities and logger config.
- `core/`: Driver singleton, Base Page Object, and Gesture utilities.
- `pages/`: Page Object classes (e.g., `login.page.js`).
- `tests/e2e/`: Mocha test scripts.
- `utils/`: Excel report generator and failure handler.
- `ai/`: Smart AI tester module.
- `reports/`: Output directory for HTML/Excel reports, logs, and failure artifacts.

## Execution
**Run locally:**
```bash
npm run test
```

**Run in CI mode (generates HTML and Excel reports):**
```bash
npm run test:ci
node utils/excelReporter.js
```

## Reports
- **HTML Report**: Found in `reports/html/index.html`
- **Excel Report**: Found in `reports/Flutter_E2E_Report.xlsx`
- **Execution Logs**: `reports/logs/execution.log`
- **Failures (Screenshots/Trees)**: `reports/failures/`
