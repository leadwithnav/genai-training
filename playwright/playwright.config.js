// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
    testDir: './tests',
    fullyParallel: true,
    retries: 0,
    workers: 1,

    // Use HTML reporter
    reporter: [
        ['list'],
        ['html', { outputFolder: 'test-results', open: 'never' }]
    ],

    use: {
        // Base URL for tests
        baseURL: 'http://localhost:3000',

        // Record trace for failed tests
        trace: 'on-first-retry',
        viewport: { width: 1280, height: 720 },
        headless: true, // Set false to see browser
    },

    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        },
        {
            name: 'firefox',
            use: { ...devices['Desktop Firefox'] },
        },
        {
            name: 'webkit',
            use: { ...devices['Desktop Safari'] },
        },
    ],
});
