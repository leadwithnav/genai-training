/**
 * Regression Test Suite — Broader Scenario Coverage
 *
 * Runs only after the smoke suite passes in CI.
 * Tests cart management and the checkout flow in more depth.
 *
 * Covered flows:
 *   TC-R01  Add item to cart, then remove it — cart should become empty
 *   TC-R02  Update cart item quantity (increment then decrement)
 *   TC-R03  Checkout button opens the checkout confirmation modal
 */

const { test, expect } = require('@playwright/test');
const { HomePage }   = require('../../pages/HomePage');
const { CommonPage } = require('../../pages/CommonPage');
const { CartPage }   = require('../../pages/CartPage');

// ─── Shared helper ─────────────────────────────────────────────────────────────
/**
 * Adds the product at `index` to the cart and returns its display name.
 * Automatically accepts the "Item added to cart!" alert fired by the app.
 *
 * @param {import('@playwright/test').Page} page
 * @param {number} [index=0]   Zero-based index of the product card to add
 * @returns {Promise<string>}  Trimmed product name read from the card's <h3>
 */
async function addProductAndGetName(page, index = 0) {
    const homePage   = new HomePage(page);
    const commonPage = new CommonPage(page);

    // Wait for the target card to be fully rendered (products load async)
    const productCard = homePage.productCards.nth(index);
    await expect(productCard).toBeVisible({ timeout: 10000 });

    // Capture the product name before clicking so we can look it up in the cart
    const productName = (await productCard.locator('h3').innerText()).trim();

    // Accept the success alert BEFORE the click so the handler is ready
    page.once('dialog', async dialog => {
        await dialog.accept();
    });

    await homePage.addProductToCart(index);

    // Wait for the cart badge to reflect the newly added item
    // This confirms the add request completed before we navigate to the cart page
    await expect(commonPage.cartCountBadge).not.toHaveText('0', { timeout: 5000 });

    return productName;
}
// ──────────────────────────────────────────────────────────────────────────────

test.describe('Regression Suite — Cart & Checkout Flows', () => {

    // Navigate to the homepage (and wait for products) before every test
    test.beforeEach(async ({ page }) => {
        await page.goto('/');
    });

    // ── TC-R01 ──────────────────────────────────────────────────────────────
    test('TC-R01: Add item to cart then remove it — cart should be empty', async ({ page }) => {
        const commonPage = new CommonPage(page);
        const cartPage   = new CartPage(page);

        // Add a product and capture its name for locating it inside the cart
        const productName = await addProductAndGetName(page, 0);

        // Navigate to the cart
        await commonPage.navigateToCart();
        await expect(cartPage.cartHeading).toBeVisible();

        // The added product must appear in #cart-items
        const cartItem = cartPage.getCartItem(productName);
        await expect(cartItem).toBeVisible({ timeout: 5000 });

        // removeFromCart() calls confirm('Remove this item?') — accept it.
        // The handler must be registered BEFORE the Remove button is clicked.
        page.once('dialog', async dialog => {
            await dialog.accept();
        });

        await cartPage.removeItem(productName);

        // After removal, app re-renders the cart and shows the empty state message
        await expect(cartPage.emptyMessage).toBeVisible({ timeout: 5000 });
    });

    // ── TC-R02 ──────────────────────────────────────────────────────────────
    test('TC-R02: Cart item quantity — increment then decrement', async ({ page }) => {
        const commonPage = new CommonPage(page);
        const cartPage   = new CartPage(page);

        const productName = await addProductAndGetName(page, 0);

        await commonPage.navigateToCart();
        await expect(cartPage.cartHeading).toBeVisible();

        // Starting quantity for a freshly added item must be 1
        const initialQty = await cartPage.getCartItemQuantity(productName);
        expect(initialQty.trim()).toBe('1');

        // Click the "+" (increment) button to request quantity = 2
        await cartPage.incrementQuantity(productName);

        // loadCart() is async (PUT → re-fetch → re-render); poll until DOM updates
        await expect(async () => {
            const qty = await cartPage.getCartItemQuantity(productName);
            expect(qty.trim()).toBe('2');
        }).toPass({ timeout: 5000 });

        // Click the "−" (decrement) button to bring the quantity back to 1
        await cartPage.decrementQuantity(productName);

        await expect(async () => {
            const qty = await cartPage.getCartItemQuantity(productName);
            expect(qty.trim()).toBe('1');
        }).toPass({ timeout: 5000 });
    });

    // ── TC-R03 ──────────────────────────────────────────────────────────────
    test('TC-R03: Checkout button should open the checkout confirmation modal', async ({ page }) => {
        const commonPage = new CommonPage(page);
        const cartPage   = new CartPage(page);

        // Cart must have at least one item for checkout() to open the modal
        await addProductAndGetName(page, 0);

        await commonPage.navigateToCart();
        await expect(cartPage.cartHeading).toBeVisible();

        // Confirm the "Proceed to Checkout" button is available in the cart
        await expect(cartPage.checkoutButton).toBeVisible({ timeout: 5000 });

        // Click the button — app.js calls checkout() which removes the "hidden"
        // class from #checkout-modal (regardless of wallet balance)
        await cartPage.checkoutButton.click();

        // The checkout modal must now be visible on screen
        const checkoutModal = page.locator('#checkout-modal');
        await expect(checkoutModal).toBeVisible({ timeout: 5000 });

        // Verify the modal shows the expected "Confirm Purchase" heading
        await expect(checkoutModal.locator('h3')).toHaveText('Confirm Purchase');
    });

});
