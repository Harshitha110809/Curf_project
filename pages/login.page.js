const BasePage = require('../core/basePage');

class LoginPage extends BasePage {
    // Locators using Flutter Finders
    get usernameInput() { return this.byKey('username_input'); }
    get passwordInput() { return this.byKey('password_input'); }
    get loginButton() { return this.byKey('login_button'); }
    get errorMessage() { return this.byKey('error_message'); }
    
    // Actions
    async login(username, password) {
        await this.typeText(this.usernameInput, username);
        await this.typeText(this.passwordInput, password);
        await this.click(this.loginButton);
    }

    async getErrorMessage() {
        return await this.getText(this.errorMessage);
    }
}

module.exports = new LoginPage();
