const driverFactory = require('../core/driver');
const logger = require('../config/logger');

class SmartTester {
    get driver() {
        return driverFactory.getDriver();
    }

    /**
     * Extracts the current UI tree and parses actionable widgets.
     * In a full AI implementation, this tree could be sent to an LLM for test generation.
     */
    async analyzeScreen() {
        logger.info('Analyzing current screen...');
        try {
            // Get Render Tree from Flutter Driver
            const tree = await this.driver.execute('flutter:getRenderTree');
            
            // Heuristics: Look for typical widget names in the tree
            const actionableWidgets = this.parseTreeForWidgets(tree);
            
            logger.info(`Discovered ${actionableWidgets.length} potential actionable widgets.`);
            
            if (actionableWidgets.length > 0) {
                logger.info('Suggested Test Scenarios:');
                actionableWidgets.forEach(widget => {
                    if (widget.type.includes('TextField')) {
                        logger.info(`- Validate empty input for ${widget.name}`);
                        logger.info(`- Validate valid/invalid format for ${widget.name}`);
                    } else if (widget.type.includes('Button')) {
                        logger.info(`- Verify navigation/action on clicking ${widget.name}`);
                    } else if (widget.type.includes('Toggle')) {
                        logger.info(`- Verify state change for ${widget.name}`);
                    }
                });
            } else {
                logger.info('No obvious actionable widgets discovered on this screen.');
            }

            return actionableWidgets;
        } catch (error) {
            logger.error(`Failed to analyze screen: ${error.message}`);
            return [];
        }
    }

    /**
     * Basic parsing heuristic for a Flutter Render Tree string
     */
    parseTreeForWidgets(treeString) {
        const widgets = [];
        const lines = treeString.split('\n');
        
        lines.forEach(line => {
            if (line.includes('TextField') || line.includes('TextFormField')) {
                widgets.push({ type: 'TextField', name: this.extractKeyOrSemantics(line) });
            }
            if (line.includes('ElevatedButton') || line.includes('TextButton') || line.includes('IconButton')) {
                widgets.push({ type: 'Button', name: this.extractKeyOrSemantics(line) });
            }
            if (line.includes('Checkbox') || line.includes('Radio') || line.includes('Switch')) {
                widgets.push({ type: 'Toggle', name: this.extractKeyOrSemantics(line) });
            }
        });
        
        return widgets;
    }

    extractKeyOrSemantics(line) {
        const keyMatch = line.match(/ValueKey\('([^']+)'\)/);
        if (keyMatch) return keyMatch[1];
        
        const semanticsMatch = line.match(/semanticsLabel:\s*"([^"]+)"/);
        if (semanticsMatch) return semanticsMatch[1];
        
        return 'Unknown_Element';
    }
}

module.exports = new SmartTester();
