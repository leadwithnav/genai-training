// @ts-check
const { defineConfig, devices } = require('@playwright/test');

module.exports = defineConfig({
    // Root directory that Playwright scans for test files
    testDir: './tests',

    // Run tests within a project in series to avoid browser resource contention
    fullyParallel: false,

    // Retry once in CI to reduce noise from transient failures; none locally
    retries: process.env.CI ? 1 : 0,

    // A single worker keeps memory usage predictable in both local and CI runs
    workers: 1,

    // Reporters:
    //  - 'list'    → real-time console feedback
    //  - 'html'    → interactive HTML report
    //               Output folder controlled by PLAYWRIGHT_HTML_REPORT env var
    //               so smoke and regression CI steps write separate directories.
    //  - 'junit'   → JUnit XML consumed by dorny/test-reporter for GitHub Checks
    //               Output file controlled by PLAYWRIGHT_JUNIT_OUTPUT env var.
    reporter: [
        ['list'],
        [
            'html',
            {
                outputFolder: process.env.PLAYWRIGHT_HTML_REPORT || 'playwright-report',
                open: 'never',
            },
        ],
        // JUnit XML — enables GitHub Check annotations via dorny/test-reporter
        [
            'junit',
            {
                outputFile: process.env.PLAYWRIGHT_JUNIT_OUTPUT || 'test-results.xml',
            },
        ],
    ],

    use: {
        // Base URL — override with PLAYWRIGHT_BASE_URL env var if needed
        baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',

        // Capture a full Playwright trace on the first retry (viewable in report)
        trace: 'on-first-retry',

        // Automatically capture a screenshot when a test fails
        screenshot: 'only-on-failure',

        // Fixed viewport keeps screenshots and layout consistent across runs
        viewport: { width: 1280, height: 720 },

        // Always headless; set to false locally when you want to watch the browser
        headless: true,
    },

    projects: [
        // ── Smoke project ───────────────────────────────────────────────────
        // Covers only critical "go / no-go" flows.
        // Run locally with:  npm run test:smoke
        // In CI this project runs first; regression is gated on its outcome.
        {
            name: 'smoke',
            testMatch: '**/smoke/**/*.spec.js',
            use: { ...devices['Desktop Chrome'] },
        },

        // ── Regression project ──────────────────────────────────────────────
        // Covers broader cart and checkout scenarios.
        // Run locally with:  npm run test:regression
        // In CI this project only runs if smoke passes.
        {
            name: 'regression',
            testMatch: '**/regression/**/*.spec.js',
            use: { ...devices['Desktop Chrome'] },
        },
    ],
});
