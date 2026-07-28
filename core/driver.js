const { remote } = require('webdriverio');
const capabilities = require('../config/capabilities');
const logger = require('../config/logger');

class DriverFactory {
    constructor() {
        this.driver = null;
    }

    async initDriver() {
        if (this.driver) {
            logger.info('Driver is already initialized.');
            return this.driver;
        }

        logger.info('Initializing Appium Flutter Driver...');
        try {
            this.driver = await remote({
                path: '/',
                port: 4723,
                capabilities: capabilities
            });
            logger.info('Driver initialized successfully.');
            return this.driver;
        } catch (error) {
            logger.error(`Failed to initialize driver: ${error.message}`);
            throw error;
        }
    }

    getDriver() {
        if (!this.driver) {
            throw new Error('Driver is not initialized. Call initDriver() first.');
        }
        return this.driver;
    }

    async quitDriver() {
        if (this.driver) {
            logger.info('Quitting driver...');
            await this.driver.deleteSession();
            this.driver = null;
            logger.info('Driver quit successfully.');
        }
    }
}

module.exports = new DriverFactory();
