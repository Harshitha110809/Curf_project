const logger = require('../config/logger');
const driverFactory = require('./driver');

class Gestures {
    get driver() {
        return driverFactory.getDriver();
    }

    async scrollUntilVisible(finder, scrollViewFinder, direction = 'down') {
        logger.info(`Scrolling ${direction} to find element: ${finder}`);
        try {
            await this.driver.execute('flutter:scrollUntilVisible', finder, {
                item: finder,
                scrollView: scrollViewFinder,
                alignment: 0.1,
                dxScroll: direction === 'right' ? -100 : (direction === 'left' ? 100 : 0),
                dyScroll: direction === 'down' ? -100 : (direction === 'up' ? 100 : 0)
            });
        } catch (error) {
            logger.error(`Failed to scroll to element: ${error.message}`);
            throw error;
        }
    }

    async swipe(finder, dx, dy, duration = 1000) {
        logger.info(`Swiping element ${finder} dx: ${dx}, dy: ${dy}`);
        await this.driver.execute('flutter:scroll', finder, { dx, dy, durationMilliseconds: duration, frequency: 60 });
    }

    async longPress(finder, duration = 2000) {
        logger.info(`Long pressing element ${finder}`);
        await this.driver.execute('flutter:longTap', finder, { durationMilliseconds: duration });
    }
    
    // Note: For advanced native gestures like Pinch/Zoom/DragAndDrop, 
    // it's often required to switch to 'NATIVE_APP' context and use W3C Actions.
}

module.exports = new Gestures();
