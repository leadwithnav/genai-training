// cypress/pages/CartPage.js
// Page Object for the GenAI Store cart page

class CartPage {
  // Selectors
  get heading() {
    return cy.contains('h2', 'Your Cart');
  }

  get cartTotal() {
    return cy.get('#cart-total');
  }

  get checkoutButton() {
    return cy.contains('button', 'Proceed to Checkout');
  }

  cartItem(productName) {
    return cy.get('#cart-items').contains('h3', productName).parents('.card');
  }

  itemQuantity(productName) {
    return this.cartItem(productName).find('.qty-control span');
  }

  itemTotal(productName) {
    return this.cartItem(productName).find('[style*="font-weight: 700"]');
  }

  // Actions
  incrementQuantity(productName) {
    this.cartItem(productName).find('button.btn-qty').contains('+').click();
  }

  decrementQuantity(productName) {
    this.cartItem(productName).find('button.btn-qty').contains('-').click();
  }

  removeItem(productName) {
    this.cartItem(productName).find('button.btn-remove').click();
  }
}

module.exports = new CartPage();
