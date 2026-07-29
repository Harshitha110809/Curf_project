const logger = require('../core/logger');

class BasePage {
    
    /**
     * Finds an element using Appium Flutter Driver finders or UiAutomator2 finders.
     * @param {string} locator Strategy and value (e.g., '~accessibilityId', '-android uiautomator:new UiSelector().text("Login")')
     */
    async getElement(locator) {
        // Simple wrapper around driver.$()
        return await $(locator);
    }

    async click(locator) {
        try {
            logger.info(`Clicking element: ${locator}`);
            const el = await this.getElement(locator);
            await el.waitForDisplayed({ timeout: 10000 });
            await el.click();
        } catch (error) {
            logger.error(`Failed to click element: ${locator} - ${error.message}`);
            throw error;
        }
    }

    async setValue(locator, value) {
        try {
            logger.info(`Setting value '${value}' to element: ${locator}`);
            const el = await this.getElement(locator);
            await el.waitForDisplayed({ timeout: 10000 });
            await el.setValue(value);
            // Flutter workaround to ensure keyboard closes if needed
            if (driver.isKeyboardShown && await driver.isKeyboardShown()) {
                await driver.hideKeyboard();
            }
        } catch (error) {
            logger.error(`Failed to set value for element: ${locator} - ${error.message}`);
            throw error;
        }
    }

    async getText(locator) {
        try {
            logger.info(`Getting text from element: ${locator}`);
            const el = await this.getElement(locator);
            await el.waitForDisplayed({ timeout: 10000 });
            return await el.getText();
        } catch (error) {
            logger.error(`Failed to get text from element: ${locator} - ${error.message}`);
            throw error;
        }
    }

    async isDisplayed(locator) {
        try {
            logger.info(`Checking if element is displayed: ${locator}`);
            const el = await this.getElement(locator);
            return await el.isDisplayed();
        } catch (error) {
            return false;
        }
    }
}

module.exports = BasePage;
