const { expect } = require('@playwright/test');

exports.CartPage = class CartPage {
  constructor(page) {
    this.page = page;

    // Cart page heading
    this.cartHeading = page.getByRole('heading', { name: 'Your Cart', level: 2 });

    // Cart items container — scoped to avoid matching product listing cards
    this.cartSection = page.locator('#cart-items');

    // Total amount span (contains just the numeric value, e.g. "399.98")
    this.cartTotalAmount = page.locator('#cart-total');

    // Checkout button
    this.checkoutButton = page.getByRole('button', { name: 'Proceed to Checkout' });

    // Empty cart message
    this.emptyMessage = page.locator('p').filter({ hasText: 'Your cart is empty.' });
  }

  /**
   * Returns a locator for a specific cart item by product name.
   * @param {string} productName
   */
  getCartItem(productName) {
    return this.cartSection.locator('.card').filter({ hasText: productName });
  }

  /**
   * Returns the text content of the quantity span for the given product.
   * The quantity span sits inside `.qty-control` between the `-` and `+` buttons.
   * @param {string} productName
   * @returns {Promise<string>} e.g. "2"
   */
  async getCartItemQuantity(productName) {
    const cartItem = this.getCartItem(productName);
    return await cartItem.locator('.qty-control span').innerText();
  }

  /**
   * Returns the formatted total amount string, e.g. "399.98"
   * @returns {Promise<string>}
   */
  async getCartTotal() {
    return await this.cartTotalAmount.innerText();
  }

  /**
   * Clicks the Remove button for a specific cart item.
   * @param {string} productName
   */
  async removeItem(productName) {
    const cartItem = this.getCartItem(productName);
    await cartItem.getByRole('button', { name: 'Remove' }).click();
  }

  /**
   * Clicks the `+` (increment) button for a specific cart item.
   * @param {string} productName
   */
  async incrementQuantity(productName) {
    const cartItem = this.getCartItem(productName);
    // The + button is the last .btn-qty within the qty-control
    await cartItem.locator('.btn-qty').last().click();
  }

  /**
   * Clicks the `-` (decrement) button for a specific cart item.
   * @param {string} productName
   */
  async decrementQuantity(productName) {
    const cartItem = this.getCartItem(productName);
    // The - button is the first .btn-qty within the qty-control
    await cartItem.locator('.btn-qty').first().click();
  }
};
