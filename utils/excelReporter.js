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

    // The 4 requested sheets
    const sheets = {
        'Appium': workbook.addWorksheet('Appium Mobile Tests'),
        'Selenium': workbook.addWorksheet('Selenium Web Tests'),
        'Load': workbook.addWorksheet('Performance Load Tests'),
        'Security': workbook.addWorksheet('Vulnerability Tests')
    };

    // Setup headers for all 4 sheets
    Object.values(sheets).forEach(sheet => {
        sheet.columns = [
            { header: 'Test ID & Name', key: 'title', width: 80 },
            { header: 'Status', key: 'state', width: 20 },
            { header: 'Duration (ms)', key: 'duration', width: 15 }
        ];
        sheet.getRow(1).font = { bold: true };
    });

    if (reportData.results) {
        reportData.results.forEach(result => {
            result.suites.forEach(suite => {
                // Determine which sheet to place this suite's tests into
                let targetSheet;
                if (suite.title.includes('[Appium]')) targetSheet = sheets['Appium'];
                else if (suite.title.includes('[Selenium]')) targetSheet = sheets['Selenium'];
                else if (suite.title.includes('[Load]')) targetSheet = sheets['Load'];
                else if (suite.title.includes('[Security]')) targetSheet = sheets['Security'];
                else targetSheet = sheets['Appium']; // fallback

                suite.tests.forEach(test => {
                    // Convert 'passed' to a tick mark ✓
                    const statusIcon = test.state === 'passed' ? '✓ Passed' : (test.state === 'failed' ? '❌ Failed' : '⏸ Skipped');
                    
                    targetSheet.addRow({
                        title: test.title,
                        state: statusIcon,
                        duration: test.duration || 0
                    });
                });
            });
        });
    }

    const excelPath = path.join(process.cwd(), 'reports', 'Flutter_E2E_Report.xlsx');
    await workbook.xlsx.writeFile(excelPath);
    console.log(`Excel report generated with 4 sheets at: ${excelPath}`);
}

if (require.main === module) {
    generateExcelReport();
}

module.exports = generateExcelReport;
