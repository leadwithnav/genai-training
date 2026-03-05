const { expect } = require('@playwright/test');

exports.CommonPage = class CommonPage {
  constructor(page) {
    this.page = page;
    this.cartLink = page.getByRole('link', { name: /Cart/ });
    this.cartCountBadge = page.locator('#cart-count');
    this.walletLink = page.getByRole('link', { name: 'Wallet' });
    this.ordersLink = page.getByRole('link', { name: 'My Orders' });
    this.productsLink = page.getByRole('link', { name: 'Products' });
    this.mainContent = page.locator('#main-content');
  }

  async navigateToCart() {
    await this.cartLink.click();
  }

  async navigateToOrders() {
    await this.ordersLink.click();
  }

  async navigateToWallet() {
    await this.walletLink.click();
  }

  async navigateToHome() {
    await this.productsLink.click();
  }

  async getCartCount() {
    const text = await this.cartCountBadge.innerText();
    return parseInt(text, 10);
  }
};
