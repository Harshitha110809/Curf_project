const BasePage = require('./basePage');
const logger = require('../core/logger');

class LoginPage extends BasePage {
    
    // Locators updated to work dynamically with UiAutomator2 on Flutter Release builds
    get emailField() { return '(//android.widget.EditText)[1]'; } // First input is Email
    get passwordField() { return '(//android.widget.EditText)[2]'; } // Second input is Password
    get loginButton() { return '//android.widget.Button'; } // The Sign In button
    get errorMessage() { return '//*[contains(@text, "Please enter both") or contains(@content-desc, "Please enter both") or contains(@text, "Incorrect") or contains(@content-desc, "Incorrect") or contains(@text, "failed") or contains(@content-desc, "failed")]'; }
    get logoutButton() { return '//*[contains(@text, "Logout") or contains(@content-desc, "Logout") or contains(@text, "Sign Out") or contains(@content-desc, "Sign Out")]'; }
    get homeScreenHeader() { return '//*[contains(@text, "Dashboard") or contains(@content-desc, "Dashboard") or contains(@text, "Welcome") or contains(@content-desc, "Welcome")]'; }

    // Alternative Flutter Finders (If using specific custom commands for appium-flutter-driver)
    // get emailFieldByText() { return '-ios class chain:**/XCUIElementTypeTextField[`name == "Email"`]'; } // Example fallback

    async login(email, password) {
        logger.info(`Attempting login with email: ${email}`);
        if (email) await this.setValue(this.emailField, email);
        if (password) await this.setValue(this.passwordField, password);
        await this.click(this.loginButton);
    }

    async getLoginError() {
        return await this.getText(this.errorMessage);
    }

    async isLoggedIn() {
        return await this.isDisplayed(this.homeScreenHeader);
    }

    async logout() {
        logger.info('Logging out...');
        await this.click(this.logoutButton);
    }
}

module.exports = new LoginPage();
