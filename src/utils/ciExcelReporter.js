const fs = require('fs');
const path = require('path');
const { generateExcelReport } = require('./excelReporter');

async function run() {
    console.log('Generating Excel Report from CI Mochawesome data...');
    try {
        const mochaReportPath = path.join(process.cwd(), 'reports', 'mochawesome.json');
        if (!fs.existsSync(mochaReportPath)) {
            console.error('Mochawesome report not found at', mochaReportPath);
            return;
        }

        const data = JSON.parse(fs.readFileSync(mochaReportPath, 'utf8'));
        const stats = data.stats || {};
        
        // Map mochawesome stats to the format expected by our excelReporter
        const results = {
            finished: stats.tests || 0,
            passed: stats.passes || 0,
            failed: stats.failures || 0
        };

        await generateExcelReport(results);
        console.log('Successfully generated Excel report for CI!');
    } catch (error) {
        console.error('Failed to generate CI Excel report:', error);
    }
}

run();
