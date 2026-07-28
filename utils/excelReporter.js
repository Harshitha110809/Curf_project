const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function generateExcelReport() {
    const jsonPath = path.join(process.cwd(), 'reports', 'html', 'mochawesome.json');
    if (!fs.existsSync(jsonPath)) {
        console.error('Mochawesome JSON report not found. Run tests first.');
        return;
    }

    const reportData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    const workbook = new ExcelJS.Workbook();
    
    // Sheet 1 - Summary
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.columns = [
        { header: 'Metric', key: 'metric', width: 20 },
        { header: 'Value', key: 'value', width: 30 }
    ];
    summarySheet.addRow({ metric: 'Execution Date', value: new Date().toISOString() });
    
    // Safely parse mochawesome stats
    if (reportData.stats) {
        summarySheet.addRow({ metric: 'Total Tests', value: reportData.stats.tests });
        summarySheet.addRow({ metric: 'Passed', value: reportData.stats.passes });
        summarySheet.addRow({ metric: 'Failed', value: reportData.stats.failures });
        summarySheet.addRow({ metric: 'Skipped', value: reportData.stats.pending });
        summarySheet.addRow({ metric: 'Pass Percentage', value: `${reportData.stats.passPercent}%` });
        summarySheet.addRow({ metric: 'Duration (ms)', value: reportData.stats.duration });
    }
    
    // Sheet 2 - Test Cases
    const testCasesSheet = workbook.addWorksheet('Test Cases');
    testCasesSheet.columns = [
        { header: 'Test Name', key: 'title', width: 50 },
        { header: 'Status', key: 'state', width: 15 },
        { header: 'Duration (ms)', key: 'duration', width: 15 }
    ];

    // Sheet 3 - Failed Tests
    const failedSheet = workbook.addWorksheet('Failed Tests');
    failedSheet.columns = [
        { header: 'Test Name', key: 'title', width: 50 },
        { header: 'Failure Reason', key: 'error', width: 80 }
    ];

    if (reportData.results) {
        reportData.results.forEach(result => {
            result.suites.forEach(suite => {
                suite.tests.forEach(test => {
                    testCasesSheet.addRow({
                        title: test.title,
                        state: test.state || 'skipped',
                        duration: test.duration || 0
                    });
                    
                    if (test.state === 'failed') {
                        failedSheet.addRow({
                            title: test.title,
                            error: test.err ? test.err.message : 'Unknown'
                        });
                    }
                });
            });
        });
    }

    // Sheet 4 - Execution Logs
    const logSheet = workbook.addWorksheet('Execution Logs');
    logSheet.columns = [
        { header: 'Log Content', key: 'content', width: 100 }
    ];
    const logFile = path.join(process.cwd(), 'reports', 'logs', 'execution.log');
    if (fs.existsSync(logFile)) {
        const logs = fs.readFileSync(logFile, 'utf8').split('\n');
        logs.forEach(line => {
            if (line.trim()) {
                logSheet.addRow({ content: line });
            }
        });
    }

    const excelPath = path.join(process.cwd(), 'reports', 'Flutter_E2E_Report.xlsx');
    await workbook.xlsx.writeFile(excelPath);
    console.log(`Excel report generated at: ${excelPath}`);
}

if (require.main === module) {
    generateExcelReport();
}

module.exports = generateExcelReport;
