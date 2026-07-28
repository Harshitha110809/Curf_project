const logger = require('../config/logger');
const driverFactory = require('./driver');
const { byValueKey, byText, byType, bySemanticsLabel } = require('appium-flutter-driver');

class BasePage {
    get driver() {
        return driverFactory.getDriver();
    }

    async waitForElement(finder, timeout = 10000) {
        logger.info(`Waiting for element: ${finder}`);
        try {
            await this.driver.execute('flutter:waitFor', finder, timeout);
            return finder;
        } catch (error) {
            logger.error(`Element ${finder} not found within ${timeout}ms.`);
            throw error;
        }
    }

    async click(finder) {
        logger.info(`Clicking on element: ${finder}`);
        await this.waitForElement(finder);
        await this.driver.elementClick(finder);
    }

    async typeText(finder, text) {
        logger.info(`Typing text into element: ${finder}`);
        await this.waitForElement(finder);
        await this.click(finder);
        await this.driver.execute('flutter:enterText', text);
    }

    async getText(finder) {
        logger.info(`Getting text from element: ${finder}`);
        await this.waitForElement(finder);
        return await this.driver.getElementText(finder);
    }

    async isElementPresent(finder) {
        try {
            await this.waitForElement(finder, 2000);
            return true;
        } catch (e) {
            return false;
        }
    }

    // Flutter Finders Helper Methods
    byKey(key) {
        return byValueKey(key);
    }

    byText(text) {
        return byText(text);
    }

    byLabel(label) {
        return bySemanticsLabel(label);
    }

    byType(type) {
        return byType(type);
    }
}

module.exports = BasePage;
