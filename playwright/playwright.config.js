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
    //  - 'list'  → real-time console feedback
    //  - 'html'  → interactive HTML report
    //             The output folder is controlled by the PLAYWRIGHT_HTML_REPORT
    //             environment variable so that smoke and regression CI steps
    //             each produce a separate artifact directory.
    reporter: [
        ['list'],
        [
            'html',
            {
                outputFolder: process.env.PLAYWRIGHT_HTML_REPORT || 'playwright-report',
                open: 'never',
            },
        ],
    ],

    use: {
        // Base URL — override with PLAYWRIGHT_BASE_URL env var if needed
        baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',

        // Capture a full trace on the first retry to help debug failures
        trace: 'on-first-retry',

        // Fixed viewport keeps screenshots and layout consistent across runs
        viewport: { width: 1280, height: 720 },

        // Always headless; set to false locally when watching the browser
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
