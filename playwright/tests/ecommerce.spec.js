const { test, expect } = require('@playwright/test');
const { HomePage } = require('../pages/HomePage');
const { CommonPage } = require('../pages/CommonPage');
const { CartPage } = require('../pages/CartPage');

test.describe('GenAI Store Smoke Tests', () => {

    // Run before each test
    test.beforeEach(async ({ page }) => {
        // Navigate to homepage
        await page.goto('/');
    });

    test('TC-001: Homepage should load and display products', async ({ page }) => {
        // Verify title
        await expect(page).toHaveTitle(/GenAI Store/i);

        // Verify products are visible
        // App uses class="card" for products
        const products = page.locator('.card');

        // Wait for products to load (fetch)
        await expect(products.first()).toBeVisible({ timeout: 10000 });

        // Count products
        const count = await products.count();
        console.log(`Found ${count} products`);
        expect(count).toBeGreaterThan(0);
    });

    test('TC-002: Add item to cart and verify cart count', async ({ page }) => {
        const homePage = new HomePage(page);
        const commonPage = new CommonPage(page);

        // Get initial count
        const initialCount = await commonPage.getCartCount();

        // Setup dialog handler for success message
        page.once('dialog', async dialog => {
            expect(dialog.message()).toContain('Item added to cart!');
            await dialog.accept();
        });

        // Add product
        await homePage.addProductToCart(0);

        // Verify count increments by 1
        await expect(commonPage.cartCountBadge).toHaveText(String(initialCount + 1), { timeout: 5000 });

        // Navigate to another page (Orders) and verify count persists
        await commonPage.navigateToOrders();
        await expect(commonPage.cartCountBadge).toHaveText(String(initialCount + 1));
    });

});
