const path = require('path');

const capabilities = {
    platformName: 'Android',
    'appium:automationName': 'Flutter',
    'appium:app': path.join(process.cwd(), 'app', 'app-release.apk'),
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 300,
    // The following can be specified if needed:
    // 'appium:appPackage': 'com.company.app',
    // 'appium:appActivity': 'com.company.app.MainActivity',
};

module.exports = capabilities;
