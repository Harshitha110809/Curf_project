const logger = require('../core/logger');
const fs = require('fs');
const path = require('path');

class FailureHandler {
    async handleFailure(testTitle) {
        logger.info(`Handling failure for test: ${testTitle}`);
        const timestamp = Date.now();
        const safeTitle = testTitle.replace(/\s+/g, '_');
        const failureDir = path.join(process.cwd(), 'reports', 'failures');
        
        if (!fs.existsSync(failureDir)) {
            fs.mkdirSync(failureDir, { recursive: true });
        }

        try {
            // 1. Capture Screenshot
            const screenshotPath = path.join(failureDir, `${safeTitle}_${timestamp}.png`);
            await driver.saveScreenshot(screenshotPath);
            logger.info(`Screenshot saved to ${screenshotPath}`);

            // 2. Capture Page Source (Widget Tree)
            const sourcePath = path.join(failureDir, `${safeTitle}_${timestamp}_source.xml`);
            const pageSource = await driver.getPageSource();
            fs.writeFileSync(sourcePath, pageSource);
            logger.info(`Widget tree saved to ${sourcePath}`);

            // 3. Capture Device Logs (logcat)
            const logTypes = await driver.getLogTypes();
            if (logTypes.includes('logcat')) {
                const logs = await driver.getLogs('logcat');
                const logPath = path.join(failureDir, `${safeTitle}_${timestamp}_logcat.txt`);
                const logContent = logs.map(l => `[${l.timestamp}] [${l.level}] ${l.message}`).join('\n');
                fs.writeFileSync(logPath, logContent);
                logger.info(`Device logs saved to ${logPath}`);
            }
        } catch (error) {
            logger.error(`Error during failure handling: ${error.message}`);
        }
    }
}

module.exports = new FailureHandler();
