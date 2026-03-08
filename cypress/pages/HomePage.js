// cypress/pages/HomePage.js
// Page Object for the GenAI Store product listing (home) page

class HomePage {
  // Navigation
  visit() {
    cy.visit('/');
  }

  // Header selectors
  get cartCount() {
    return cy.get('#cart-count');
  }

  get cartLink() {
    return cy.contains('a', /^Cart/);
  }

  // Product listing selectors
  productCard(productName) {
    return cy.contains('h3', productName).parents('.card');
  }

  addToCartButton(productName) {
    return this.productCard(productName).find('button.btn-primary');
  }

  // Actions
  addProductToCart(productName) {
    // Handle the native alert BEFORE clicking
    cy.on('window:alert', (alertText) => {
      expect(alertText).to.equal('Item added to cart!');
    });
    this.addToCartButton(productName).click();
  }

  navigateToCart() {
    this.cartLink.click();
  }
}

module.exports = new HomePage();
