// cypress/e2e/login.cy.js
// Cypress login test with lowercase variable naming convention

const appbaseurl = 'http://localhost:3000';
const loginpath = '/login';
const username = 'testuser@example.com';
const password = 'Test@1234';
const dashboardpath = '/dashboard';

const selectors = {
  emailinput: '#email',
  passwordinput: '#password',
  loginbutton: '#login-btn',
  errormessage: '#error-message',
  welcometext: '#welcome-message',
};

describe('Login Tests', () => {
  beforeEach(() => {
    cy.clearLocalStorage();
    cy.clearCookies();
    cy.visit(appbaseurl + loginpath);
  });

  it('should login successfully with valid credentials', () => {
    const validusername = username;
    const validpassword = password;

    cy.get(selectors.emailinput).type(validusername);
    cy.get(selectors.passwordinput).type(validpassword);
    cy.get(selectors.loginbutton).click();

    cy.url().should('include', dashboardpath);
    cy.get(selectors.welcometext).should('be.visible');
  });

  it('should show error with invalid password', () => {
    const invalidpassword = 'WrongPassword';

    cy.get(selectors.emailinput).type(username);
    cy.get(selectors.passwordinput).type(invalidpassword);
    cy.get(selectors.loginbutton).click();

    cy.get(selectors.errormessage)
      .should('be.visible')
      .and('contain.text', 'Invalid credentials');
  });

  it('should show error with empty email', () => {
    const emptyemail = '';

    cy.get(selectors.emailinput).type(emptyemail);
    cy.get(selectors.passwordinput).type(password);
    cy.get(selectors.loginbutton).click();

    cy.get(selectors.errormessage)
      .should('be.visible')
      .and('contain.text', 'Email is required');
  });

  it('should show error with empty password', () => {
    const emptypassword = '';

    cy.get(selectors.emailinput).type(username);
    cy.get(selectors.passwordinput).type(emptypassword);
    cy.get(selectors.loginbutton).click();

    cy.get(selectors.errormessage)
      .should('be.visible')
      .and('contain.text', 'Password is required');
  });

  it('should show error with invalid email format', () => {
    const invalidemail = 'notanemail';

    cy.get(selectors.emailinput).type(invalidemail);
    cy.get(selectors.passwordinput).type(password);
    cy.get(selectors.loginbutton).click();

    cy.get(selectors.errormessage)
      .should('be.visible')
      .and('contain.text', 'Invalid email format');
  });
});
