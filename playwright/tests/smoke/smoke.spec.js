/**
 * Smoke Test Suite — Critical Path Verification
 *
 * These tests confirm that the most important user flows are functioning.
 * They run FIRST in CI; if any fail, the regression suite is skipped.
 *
 * Covered flows:
 *   TC-S01  Homepage loads and products are displayed
 *   TC-S02  Add first product to cart — cart badge increments
 *   TC-S03  Navigate to cart page — heading is visible
 */

const { test, expect } = require('@playwright/test');
const { HomePage }   = require('../../pages/HomePage');
const { CommonPage } = require('../../pages/CommonPage');
const { CartPage }   = require('../../pages/CartPage');

test.describe('Smoke Suite — Critical Flows', () => {

    // Navigate to the homepage before every test
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
    });

    // ── TC-S01 ────────────────────────────────────────────────────────────────
    test('TC-S01: Homepage should load and display products', async ({ page }) => {
        // Verify the browser tab title matches the expected app name
        // TODO: revert — intentionally wrong title to trigger AI Analysis
        await expect(page).toHaveTitle(/GenAI Superstore/i);

        // Products are rendered with the .card CSS class by app.js
        const products = page.locator('.card');

        // Wait up to 10 s for at least one card (products are fetched async)
        await expect(products.first()).toBeVisible({ timeout: 10000 });

        // Sanity-check: the product list must not be empty
        const count = await products.count();
        expect(count).toBeGreaterThan(0);
    });

    // ── TC-S02 ────────────────────────────────────────────────────────────────
    test('TC-S02: Add first product to cart — cart badge should increment', async ({ page }) => {
        const homePage   = new HomePage(page);
        const commonPage = new CommonPage(page);

        // Record the current cart count before adding anything
        const initialCount = await commonPage.getCartCount();

        // The app fires alert('Item added to cart!') on a successful add.
        // Register the handler BEFORE the click so it is in place when the alert fires.
        page.once('dialog', async dialog => {
            expect(dialog.message()).toContain('Item added to cart!');
            await dialog.accept();
        });

        // Click "Add to Cart" on the first product card
        await homePage.addProductToCart(0);

        // The #cart-count badge must reflect exactly one more item
        await expect(commonPage.cartCountBadge).toHaveText(
            String(initialCount + 1),
            { timeout: 5000 }
        );
    });

    // ── TC-S03 ────────────────────────────────────────────────────────────────
    test('TC-S03: Cart page should open and show the "Your Cart" heading', async ({ page }) => {
        const commonPage = new CommonPage(page);
        const cartPage   = new CartPage(page);

        // Click the Cart link in the top navigation bar
        await commonPage.navigateToCart();

        // The <h2>Your Cart</h2> heading must be visible on screen
        await expect(cartPage.cartHeading).toBeVisible({ timeout: 5000 });
    });

});
