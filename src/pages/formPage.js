const BasePage = require('./basePage');
const logger = require('../core/logger');

class FormPage extends BasePage {
    
    // Mapping to register_screen.dart fields dynamically using UiAutomator2
    get registerLink() { return '//android.widget.TextView[contains(@text, "Register Here")]'; }
    get nameField() { return '(//android.widget.EditText)[1]'; }
    get emailField() { return '(//android.widget.EditText)[2]'; }
    get passwordField() { return '(//android.widget.EditText)[3]'; }
    get regNoField() { return '(//android.widget.EditText)[4]'; }
    get phoneField() { return '(//android.widget.EditText)[5]'; }
    
    get submitButton() { return '//android.widget.Button[contains(@text, "Create Account") or contains(@content-desc, "Create Account")]'; }
    get errorMessage() { return '//android.widget.TextView[contains(@text, "Please fill") or contains(@text, "error")]'; }

    async navigateToRegister() {
        logger.info('Navigating to Register Screen...');
        await this.click(this.registerLink);
    }

    async fillForm(name, email, password, regNo, phone) {
        logger.info('Filling out Registration Form...');
        if (name) await this.setValue(this.nameField, name);
        if (email) await this.setValue(this.emailField, email);
        if (password) await this.setValue(this.passwordField, password);
        if (regNo) await this.setValue(this.regNoField, regNo);
        if (phone) await this.setValue(this.phoneField, phone);
    }

    async submitForm() {
        logger.info('Submitting Form...');
        await this.click(this.submitButton);
    }
}

module.exports = new FormPage();
