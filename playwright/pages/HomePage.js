const { expect } = require('@playwright/test');

exports.HomePage = class HomePage {
  constructor(page) {
    this.page = page;
    this.productCards = page.locator('.card');
    // We can interact with products by index or specific selectors
  }

  async goto() {
    await this.page.goto('/');
    // Wait for at least one product to ensure page loaded
    await expect(this.productCards.first()).toBeVisible({ timeout: 10000 });
  }

  async addProductToCart(index = 0) {
    const product = this.productCards.nth(index);
    const addToCartButton = product.getByRole('button', { name: 'Add to Cart' });
    
    // We need to set up the dialog listener BEFORE the click in the test, 
    // or return a promise that resolves when dialog is handled?
    // Playwright handles dialogs via page.on(), usually set up in test.
    // However, if we encapsulate the "click" here, the test needs to set up the handler first.
    // Or we can accept an optional handler here? No, better keep page object simple.
    
    await addToCartButton.click();
  }

  async getProduct(index = 0) {
    return this.productCards.nth(index);
  }

  async getProductCount() {
    return await this.productCards.count();
  }
};
