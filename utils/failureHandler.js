const fs = require('fs');
const path = require('path');
const driverFactory = require('../core/driver');
const logger = require('../config/logger');

async function handleFailure(testTitle) {
    const driver = driverFactory.driver;
    if (!driver) return;

    const failuresDir = path.join(process.cwd(), 'reports', 'failures');
    if (!fs.existsSync(failuresDir)) {
        fs.mkdirSync(failuresDir, { recursive: true });
    }

    const sanitizedTitle = testTitle.replace(/[^a-zA-Z0-9]/g, '_');
    
    try {
        // Capture Screenshot
        const screenshotPath = path.join(failuresDir, `${sanitizedTitle}.png`);
        await driver.saveScreenshot(screenshotPath);
        logger.info(`Screenshot saved to: ${screenshotPath}`);

        // Capture Flutter Render Tree
        const renderTreePath = path.join(failuresDir, `${sanitizedTitle}_tree.txt`);
        const tree = await driver.execute('flutter:getRenderTree');
        fs.writeFileSync(renderTreePath, tree);
        logger.info(`Render tree saved to: ${renderTreePath}`);

    } catch (error) {
        logger.error(`Error during failure handling for '${testTitle}': ${error.message}`);
    }
}

module.exports = { handleFailure };
