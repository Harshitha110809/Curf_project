const { expect } = require('chai');
const LoginPage = require('../../src/pages/loginPage');
const logger = require('../../src/core/logger');

describe('Authentication Testing', () => {
    
    before(async () => {
        logger.info('Starting Authentication Test Suite');
        // Ensure we are on the login screen
        const isLoginScreen = await LoginPage.isDisplayed(LoginPage.emailField);
        // expect(isLoginScreen).to.be.true; 
    });

    it('should login successfully with valid credentials', async () => {
        await LoginPage.login('indhu@gmail.com', 'indhu@gmail.com');
        const loggedIn = await LoginPage.isLoggedIn();
        expect(loggedIn).to.be.true;
    });

    it('should persist session after restart', async () => {
        const appPackage = await driver.getCurrentPackage();
        await driver.terminateApp(appPackage);
        await driver.activateApp(appPackage);
        const loggedIn = await LoginPage.isLoggedIn();
        expect(loggedIn).to.be.true;
    });
});
