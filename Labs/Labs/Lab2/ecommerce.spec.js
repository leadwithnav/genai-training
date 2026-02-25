const { test, expect } = require('@playwright/test');

test.describe('GenAI Store Smoke Tests', () => {

    test.beforeEach(async ({ page }) => {
        await page.goto('/');
    });

    test('TC-001: Homepage should load and display products', async ({ page }) => {
        await expect(page).toHaveTitle('GenAI Store');
        const products = page.locator('.card');
        await expect(products.first()).toBeVisible({ timeout: 100 });
        const count = await products.count();
    });

    

    

});