const { expect } = require('chai');
const FormPage = require('../../src/pages/formPage');
const logger = require('../../src/core/logger');

describe('Flutter Registration Form Validation Testing', () => {
    
    before(async () => {
        logger.info('Starting Registration Form Validation Test Suite');
        await FormPage.navigateToRegister();
    });

    it('should validate empty fields on submit', async () => {
        await FormPage.submitForm();
        // The app should show a SnackBar error for empty fields
        const err = await FormPage.getText(FormPage.errorMessage);
        expect(err).to.not.be.empty;
    });

    it('should fill out registration form successfully', async () => {
        await FormPage.fillForm(
            'John Doe', 
            'john.doe@campus.edu', 
            'SecurePass123!', 
            'REG123456', 
            '5551234567'
        );
        // We do not submit to avoid creating junk data in the actual Supabase database during the test.
        // But we verify the text is entered.
        const nameVal = await FormPage.getText(FormPage.nameField);
        expect(nameVal).to.include('John Doe');
    });
});
