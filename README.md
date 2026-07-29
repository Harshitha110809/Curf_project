# Flutter Appium Automation Framework

This is an enterprise-grade End-to-End (E2E) automation framework built for testing Flutter Android applications using Node.js, Appium 2.x, WebdriverIO (Mocha), and Chai.

## Features
- **Appium 2.x & WebdriverIO**: Industry-standard robust client.
- **Flutter Support**: Compatible with `appium-flutter-driver` and `UiAutomator2`.
- **Page Object Model (POM)**: Highly maintainable architecture.
- **Advanced Reporting**: Generates both `Mochawesome` HTML reports and `ExcelJS` multi-sheet `.xlsx` reports.
- **Smart AI Module (Stub)**: Foundation for AI-based test generation and dynamic field validation.
- **Failure Handling**: Automatically captures screenshots, device logs (`logcat`), and UI XML/JSON source on test failures.
- **Gestures Utility**: Reusable swipe, scroll, tap, double tap, and drag-and-drop utilities.
- **CI/CD Ready**: Fully configured GitHub Actions workflow (`.github/workflows/flutter-appium.yml`) for automated emulator setup and test execution.

## Project Structure
```
├── app/                  # Place your app-release.apk here
├── config/
│   └── wdio.conf.js      # Core Appium and Runner configuration
├── src/
│   ├── core/             # Logger, Driver setup
│   ├── pages/            # Page Objects (BasePage, LoginPage, FormPage)
│   └── utils/            # Gestures, ExcelReporter, FailureHandler, AITester
├── tests/
│   └── e2e/              # Mocha Test Suites (auth, formValidation, etc.)
├── reports/              # Generated JSON, HTML, and Excel reports
└── package.json          # Dependencies and npm scripts
```

## Setup Guide

### Prerequisites
1. **Node.js** (v18 or higher recommended)
2. **Java JDK 11+**
3. **Android SDK** (with an Emulator configured or real device connected via ADB)
4. **Appium 2.x**:
   ```bash
   npm install -g appium
   appium driver install uiautomator2
   appium driver install flutter
   ```

### Installation
1. Clone this repository.
2. Run `npm install` to install all dependencies.
3. Place your target APK inside the `app/` directory and name it `app-release.apk` (or update the path in `config/wdio.conf.js`).

### Execution
Run tests locally using the standard test command:
```bash
npm run test
```

To run tests and automatically merge/generate Mochawesome HTML reports:
```bash
npm run test:full
```

### Reports
- **HTML Report**: Found in `reports/html/report.html`
- **Excel Report**: Found at `reports/Flutter_E2E_Report.xlsx`
- **Logs**: Execution logs are found at `reports/execution.log`
- **Failures**: Screenshots and source trees for failed tests are saved in `reports/failures/`
