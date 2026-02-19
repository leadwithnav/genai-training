const { test, expect } = require('@playwright/test');

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
        // Get initial cart count
        const cartBadge = page.locator('#cart-count');

        // Click "Add to Cart" on first product
        // Use .card button
        await page.locator('.card button').first().click();

        // Handle alert dialog if any (app uses alert('Item added to cart!'))
        page.on('dialog', dialog => dialog.accept());

        // Wait for count to update (fetch)
        // Since we don't know if it was 0, we just check it increments or becomes non-zero
        await expect(cartBadge).not.toHaveText('0', { timeout: 5000 });
    });

    test('TC-003: Verify Cart Page', async ({ page }) => {
        // Add item first
        page.on('dialog', dialog => dialog.accept());
        await page.locator('.card button').first().click();

        // Navigate to Cart
        await page.getByRole('link', { name: /Cart/ }).click();

        // Check if cart section is visible
        const cartSection = page.locator('#cart-page');
        await expect(cartSection).not.toHaveClass(/hidden/);

        // Product should be in list
        // Cart items also use .card class in cart-items div
        await expect(page.locator('#cart-items .card')).toBeVisible();

        // Verify total price is displayed
        await expect(page.locator('#cart-total')).not.toHaveText('0.00');
    });

    test('TC-004: Wallet functionality (Add Funds)', async ({ page }) => {
        // Go to Wallet page
        await page.getByRole('link', { name: 'Wallet' }).click();

        // Check initial balance
        const balanceEl = page.locator('#wallet-balance');
        await expect(balanceEl).toBeVisible();
        const initialBalance = await balanceEl.innerText();

        // Add funds
        const amountRef = '100';
        await page.locator('#add-amount').fill(amountRef);

        page.on('dialog', dialog => dialog.accept());
        await page.getByRole('button', { name: 'Add Funds' }).click();

        // Verify balance updated
        // Simple check: wait for it to change or increase
        // Note: float comparisons might be tricky with text, but let's try strict increase check
        await expect(async () => {
            const newBalance = await balanceEl.innerText();
            expect(parseFloat(newBalance)).toBeGreaterThan(parseFloat(initialBalance));
        }).toPass();
    });

    test('TC-005: Checkout Flow (End-to-End)', async ({ page }) => {
        page.on('dialog', dialog => dialog.accept());

        // 1. Add Funds to cover purchase (ensure we have enough)
        await page.getByRole('link', { name: 'Wallet' }).click();
        await page.locator('#add-amount').fill('500'); // Should be enough for one item
        await page.getByRole('button', { name: 'Add Funds' }).click();

        // 2. Add Product to Cart
        await page.getByRole('link', { name: 'Products' }).click();
        await page.locator('.card button').first().click();

        // 3. Go to Cart
        await page.getByRole('link', { name: /Cart/ }).click();

        // 4. Checkout
        await page.getByRole('button', { name: 'Proceed to Checkout' }).click();

        // 5. Handle Modal
        const modal = page.locator('#checkout-modal');
        await expect(modal).not.toHaveClass(/hidden/);

        // Wait for modal calculation
        await page.waitForTimeout(500);

        // Confirm
        await page.locator('#btn-confirm-pay').click();

        // 6. Verify Success Page
        const successSection = page.locator('#success-page');
        await expect(successSection).not.toHaveClass(/hidden/);
        await expect(successSection.locator('h2')).toContainText('Order Confirmed');
        await expect(page.locator('#order-id')).toBeVisible();
    });

});
