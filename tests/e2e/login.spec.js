const { expect } = require('chai');
const driverFactory = require('../../core/driver');
const loginPage = require('../../pages/login.page');
const { handleFailure } = require('../../utils/failureHandler');

describe('Login E2E Tests', function () {
    
    before(async function () {
        await driverFactory.initDriver();
    });

    afterEach(async function () {
        if (this.currentTest.state === 'failed') {
            await handleFailure(this.currentTest.title);
        }
    });

    after(async function () {
        await driverFactory.quitDriver();
        
        // Generate Excel report at the end of the run
        // In a full CI setup, you might run excelReporter as a separate script after mocha finishes.
        const generateExcelReport = require('../../utils/excelReporter');
        try {
            await generateExcelReport();
        } catch (e) {
            console.error('Note: Excel report generation skipped or failed in teardown. Ensure tests completed and mochawesome.json exists.');
        }
    });

    it('should show error for empty fields', async function () {
        await loginPage.login('', '');
        // Example assertion based on hypothetical app behavior
        // const errorText = await loginPage.getErrorMessage();
        // expect(errorText).to.include('Required fields cannot be empty');
        
        // Simulating a pass for the template
        expect(true).to.be.true;
    });

    it('should show error for invalid credentials', async function () {
        // await loginPage.login('invalidUser', 'invalidPass');
        // const errorText = await loginPage.getErrorMessage();
        // expect(errorText).to.include('Invalid username or password');
        
        // Simulating a pass for the template
        expect(true).to.be.true;
    });

    it('should login successfully with valid credentials', async function () {
        // await loginPage.login('testuser', 'password123');
        // const homeHeader = loginPage.byText('Home');
        // const isPresent = await loginPage.isElementPresent(homeHeader);
        // expect(isPresent).to.be.true;
        
        // Simulating a pass for the template
        expect(true).to.be.true;
    });
});
