const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function generateExcelReport(results) {
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Appium QA Automation';
    workbook.created = new Date();

    // Sheet 1 - Summary
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.columns = [
        { header: 'Metric', key: 'metric', width: 20 },
        { header: 'Value', key: 'value', width: 30 }
    ];
    
    // We get basic summary from wdio results object
    const total = results.finished;
    const passed = results.passed;
    const failed = results.failed;
    const skipped = total - passed - failed;
    const passPercent = total > 0 ? ((passed / total) * 100).toFixed(2) + '%' : '0%';

    summarySheet.addRows([
        { metric: 'Execution Date', value: new Date().toLocaleString() },
        { metric: 'Device Name', value: process.env.DEVICE_NAME || 'Emulator' },
        { metric: 'Android Version', value: process.env.ANDROID_VERSION || 'N/A' },
        { metric: 'Total Tests', value: total },
        { metric: 'Passed', value: passed },
        { metric: 'Failed', value: failed },
        { metric: 'Skipped', value: skipped },
        { metric: 'Pass Percentage', value: passPercent },
    ]);

    // Format headers
    summarySheet.getRow(1).font = { bold: true };

    // Sheet 2 - Test Cases
    const testSheet = workbook.addWorksheet('Test Cases');
    testSheet.columns = [
        { header: 'Test ID', key: 'id', width: 10 },
        { header: 'Module', key: 'module', width: 20 },
        { header: 'Scenario', key: 'scenario', width: 40 },
        { header: 'Status', key: 'status', width: 15 },
        { header: 'Device', key: 'device', width: 20 },
        { header: 'Duration', key: 'duration', width: 15 }
    ];
    testSheet.getRow(1).font = { bold: true };

    // Sheet 3 - Failed Tests
    const failSheet = workbook.addWorksheet('Failed Tests');
    failSheet.columns = [
        { header: 'Test Name', key: 'name', width: 40 },
        { header: 'Failure Reason', key: 'reason', width: 50 },
        { header: 'Screenshot Path', key: 'screenshot', width: 50 },
        { header: 'Device', key: 'device', width: 20 },
        { header: 'Android Version', key: 'version', width: 15 }
    ];
    failSheet.getRow(1).font = { bold: true };

    // Sheet 4 - Execution Logs
    const logSheet = workbook.addWorksheet('Execution Logs');
    logSheet.columns = [
        { header: 'Timestamp', key: 'time', width: 25 },
        { header: 'Test Name', key: 'test', width: 40 },
        { header: 'Step', key: 'step', width: 40 },
        { header: 'Result', key: 'result', width: 15 },
        { header: 'Remarks', key: 'remarks', width: 30 }
    ];
    logSheet.getRow(1).font = { bold: true };

    // Parse mochawesome json files to populate the sheets
    const reportsDir = path.join(process.cwd(), 'reports', 'json');
    if (fs.existsSync(reportsDir)) {
        const files = fs.readdirSync(reportsDir).filter(f => f.endsWith('.json'));
        let testId = 1;
        for (const file of files) {
            const data = JSON.parse(fs.readFileSync(path.join(reportsDir, file), 'utf8'));
            data.results.forEach(suite => {
                suite.suites.forEach(subSuite => {
                    subSuite.tests.forEach(test => {
                        testSheet.addRow({
                            id: `TC_${testId++}`,
                            module: suite.title,
                            scenario: test.title,
                            status: test.pass ? 'Passed' : test.fail ? 'Failed' : 'Skipped',
                            device: process.env.DEVICE_NAME || 'Emulator',
                            duration: `${test.duration} ms`
                        });

                        if (test.fail) {
                            failSheet.addRow({
                                name: test.title,
                                reason: test.err ? test.err.message : 'Unknown error',
                                screenshot: `failures/${test.title.replace(/\\s+/g, '_')}.png`,
                                device: process.env.DEVICE_NAME || 'Emulator',
                                version: process.env.ANDROID_VERSION || 'N/A'
                            });
                        }
                    });
                });
            });
        }
    }

    // Save workbook with a timestamp to prevent Windows "File in Use" errors when Excel is open!
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const reportPath = path.join(process.cwd(), 'reports', `Flutter_E2E_Report_${timestamp}.xlsx`);
    
    // Also save the default one if possible (will fail silently if user has it open)
    const defaultPath = path.join(process.cwd(), 'reports', 'Flutter_E2E_Report.xlsx');
    
    try {
        await workbook.xlsx.writeFile(reportPath);
        console.log(`Excel report saved successfully to: ${reportPath}`);
        await workbook.xlsx.writeFile(defaultPath); // Try to overwrite the main one too
    } catch (err) {
        console.error('Warning: Could not overwrite the default Excel file (is it open in Microsoft Excel?). The timestamped file was saved instead.');
    }
}

module.exports = { generateExcelReport };
