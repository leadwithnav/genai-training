// cypress/e2e/addToCart_c59.cy.js
// Cypress test for Add to Cart (C59) TestRail test case

// Cypress test converted from Playwright TC-002: Add item to cart and verify cart count

describe('TC-002: Add item to cart and verify cart count', () => {
  beforeEach(() => {
    // Visit the homepage
    cy.visit('/');
  });

  it('should add item to cart and verify cart count', () => {
    // Use cy.prompt() AI to ask for product index and user name
    cy.prompt('Enter product index to add to cart:', '0').then((productIndex) => {
      cy.prompt('Enter your name for the prompt dialog:', 'Test User').then((userName) => {
        // Get initial cart count
        cy.get('#cart-count').invoke('text').then((initialText) => {
          const initialCount = parseInt(initialText) || 0;

          // Listen for alert dialog (success message)
          cy.on('window:alert', (str) => {
            expect(str).to.contain('Item added to cart!');
          });

          // Stub window.prompt to simulate user input
          cy.window().then((win) => {
            cy.stub(win, 'prompt').returns(userName);
          });

          // Add product at the given index to cart
          cy.get('button').contains('Add to Cart').eq(Number(productIndex)).click();

          // Verify cart count increments by 1
          cy.get('#cart-count').should('have.text', String(initialCount + 1));

          // Navigate to Orders page (link with text 'My Orders')
          cy.contains('a', 'My Orders').click();
          cy.get('#cart-count').should('have.text', String(initialCount + 1));
        });
      });
    });
  });
});
