/**
 * Reusable gesture utilities for Appium tests.
 * Supports both standard W3C actions and Flutter driver specific gestures.
 */
const logger = require('../core/logger');

class Gestures {
    
    async tap(element) {
        logger.info(`Tapping on element`);
        await element.click();
    }

    async doubleTap(element) {
        logger.info(`Double tapping on element`);
        await driver.action('pointer')
            .move({ duration: 0, origin: element })
            .down()
            .pause(10)
            .up()
            .pause(40)
            .down()
            .pause(10)
            .up()
            .perform();
    }

    async longPress(element, pressDuration = 1000) {
        logger.info(`Long pressing element for ${pressDuration}ms`);
        await driver.action('pointer')
            .move({ duration: 0, origin: element })
            .down()
            .pause(pressDuration)
            .up()
            .perform();
    }

    async swipe(startX, startY, endX, endY, duration = 1000) {
        logger.info(`Swiping from (${startX},${startY}) to (${endX},${endY})`);
        await driver.action('pointer')
            .move({ duration: 0, x: startX, y: startY })
            .down()
            .move({ duration, x: endX, y: endY })
            .up()
            .perform();
    }

    async scroll(direction = 'down', duration = 500) {
        const { width, height } = await driver.getWindowRect();
        const centerX = Math.floor(width / 2);
        
        let startY, endY;
        
        if (direction === 'down') {
            startY = Math.floor(height * 0.8);
            endY = Math.floor(height * 0.2);
        } else if (direction === 'up') {
            startY = Math.floor(height * 0.2);
            endY = Math.floor(height * 0.8);
        }
        
        await this.swipe(centerX, startY, centerX, endY, duration);
    }

    async dragAndDrop(sourceElement, targetElement) {
        logger.info(`Dragging and dropping element`);
        const sourceLoc = await sourceElement.getLocation();
        const targetLoc = await targetElement.getLocation();
        
        await this.swipe(sourceLoc.x, sourceLoc.y, targetLoc.x, targetLoc.y);
    }
}

module.exports = new Gestures();
