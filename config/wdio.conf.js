const path = require('path');
const fs = require('fs');

// Ensure Android Environment Variables are ALWAYS set for Appium, regardless of the terminal used
process.env.ANDROID_HOME = "C:\\Users\\harsh\\AppData\\Local\\Android\\Sdk";
process.env.ANDROID_SDK_ROOT = "C:\\Users\\harsh\\AppData\\Local\\Android\\Sdk";
const { generateExcelReport } = require('../src/utils/excelReporter');
const logger = require('../src/core/logger');

exports.config = {
    // ====================
    // Runner Configuration
    // ====================
    runner: 'local',
    port: 4723,

    // ==================
    // Specify Test Files
    // ==================
    specs: process.env.CI ? [
        '../tests/e2e/boundaryValidation.test.js'
    ] : [
        '../tests/e2e/**/*.test.js'
    ],
    exclude: [],

    // ============
    // Capabilities
    // ============
    maxInstances: 1,
    capabilities: [{
        platformName: 'Android',
        'appium:deviceName': 'Android Emulator',
        'appium:automationName': 'UiAutomator2', // Required for Release APKs
        ...(process.env.CI ? {} : { 'appium:app': path.join(process.cwd(), 'app', 'app-release.apk') }),
        'appium:newCommandTimeout': 240,
        'appium:autoGrantPermissions': true,
        'appium:noReset': false,
        'appium:fullReset': true
    }],

    // ===================
    // Test Configurations
    // ===================
    logLevel: 'info',
    bail: 0,
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,

    // Services
    services: [
        ['appium', {
            args: {
                address: '127.0.0.1',
                port: 4723,
                relaxedSecurity: true,
                log: './reports/appium.log'
            },
            command: 'appium'
        }]
    ],

    // Framework
    framework: 'mocha',
    reporters: [
        'spec',
        ['mochawesome', {
            outputDir: './reports/json',
            outputFileFormat: function(opts) { 
                return `results-${opts.cid}.json`;
            }
        }]
    ],

    mochaOpts: {
        ui: 'bdd',
        timeout: 60000
    },

    // =====
    // Hooks
    // =====
    onPrepare: function (config, capabilities) {
        logger.info('Starting test execution...');
        if (!fs.existsSync('./reports')) fs.mkdirSync('./reports');
        if (!fs.existsSync('./reports/json')) fs.mkdirSync('./reports/json');
        if (!fs.existsSync('./reports/failures')) fs.mkdirSync('./reports/failures');
        
        // Clean old JSON files to prevent corrupted reports
        const jsonFiles = fs.readdirSync('./reports/json');
        for (const file of jsonFiles) {
            fs.unlinkSync(path.join('./reports/json', file));
        }
    },

    afterTest: async function (test, context, { error, result, duration, passed, retries }) {
        if (!passed) {
            try {
                const screenshotPath = path.join(process.cwd(), 'reports', 'failures', `${test.title.replace(/\\s+/g, '_')}_${Date.now()}.png`);
                await driver.saveScreenshot(screenshotPath);
                logger.error(`Test Failed: ${test.title}. Screenshot saved at ${screenshotPath}`);
            } catch (e) {}
        }
    },

    onComplete: async function(exitCode, config, capabilities, results) {
        logger.info('Test execution completed. Generating Excel report...');
        try {
            await generateExcelReport(results);
            logger.info('Excel report generated successfully.');
        } catch (err) {
            logger.error('Failed to generate Excel report:', err);
        }
    }
};
