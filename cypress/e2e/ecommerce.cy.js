// cypress/e2e/ecommerce.cy.js
// Cypress test for TestRail test case C60: Add to Cart - Increment Quantity
//
// Dry run findings informed the implementation:
//  - Success indicator is a native browser alert("Item added to cart!")
//  - Cart count lives in #cart-count (text only, e.g. "2")
//  - Cart nav link text is dynamic e.g. "Cart (2)" — use #cart-count instead
//  - Cart items rendered in #cart-items, each in a .card with .qty-control span for quantity
//  - Product "Add to Cart" button has class btn-primary inside a .card scoped to the product
//  - clearLocalStorage() resets sessionId so each test run starts with an empty cart

const homePage = require('../pages/HomePage');
const cartPage = require('../pages/CartPage');

describe('C60: Add to Cart - Increment Quantity', () => {
  beforeEach(() => {
    // Clearing localStorage forces a new anonymous session → empty cart
    cy.clearLocalStorage();
    homePage.visit();
  });

  it('[C60] should increment quantity when the same product is added to cart twice', () => {
    const productName = 'Quantum Keyboard';

    // Step 1: Product listing page displays available products
    cy.contains('h2', 'Future Tech for Testers').should('be.visible');
    homePage.addToCartButton(productName).should('be.visible');

    // Step 2: Add product to cart — native alert "Item added to cart!" fires and is asserted
    homePage.addProductToCart(productName);

    // Step 3: Cart count in header increments to 1
    homePage.cartCount.should('have.text', '1');

    // Step 4: Navigate back to product listing via Products nav link
    cy.contains('a', 'Products').click();
    cy.contains('h2', 'Future Tech for Testers').should('be.visible');

    // Step 5: Add the same product to cart a second time
    homePage.addProductToCart(productName);

    // Step 6: Cart count increments to 2
    homePage.cartCount.should('have.text', '2');

    // Step 7: Navigate to cart page and verify product quantity is 2
    homePage.navigateToCart();
    cartPage.heading.should('be.visible');
    cartPage.itemQuantity(productName).should('have.text', '2');
  });
});
