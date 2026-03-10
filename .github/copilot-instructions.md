# GitHub Copilot Instructions


## General Coding Standards (All Languages)
- **Clean Code:** Write clean, readable, and maintainable code.
- **Comments:** Add brief comments explaining complex logic, but prefer self-documenting code.
- **Error Handling:** Implement robust error handling where appropriate.

---

## Playwright & JavaScript/TypeScript Automation Standards (APPLY ONLY for .js, .ts, .spec.js, .spec.ts files related to UI Testing)

When generating Playwright code for this project, you MUST strictly adhere to the following guidelines:

### 1. Page Object Model (POM) Structure
- **ALWAYS** implement the Page Object Model pattern.
- Create separate Page Object classes in the `pages/` directory (e.g., `pages/LoginPage.js`, `pages/CartPage.js`).
- **NEVER** write raw locators directly in test files (`.spec.js`). All locators must reside within Page Object classes.
- Export page classes and import them into test files.
- Use constructor injection for the `page` object.

#### Example Page Object (`pages/LoginPage.js`):
```javascript
const { expect } = require('@playwright/test');

exports.LoginPage = class LoginPage {
  constructor(page) {
    this.page = page;
    this.usernameInput = page.locator('#username');
    this.passwordInput = page.locator('#password');
    this.loginButton = page.getByRole('button', { name: 'Login' });
  }

  async goto() {
    await this.page.goto('https://example.com/login');
  }

  async login(username, password) {
    await this.usernameInput.fill(username);
    await this.passwordInput.fill(password);
    await this.loginButton.click();
  }
};
```

### 2. Locators Strategy
- **Prioritize User-Visible Locators:** Use `getByRole`, `getByLabel`, `getByText`, or `getByPlaceholder` whenever possible.
- **Avoid Rigid Selectors:** Do not use complex CSS or XPath selectors (e.g., `div > div > span:nth-child(3)`).
- **Use `data-testid`:** If user-visible locators are not feasible, rely on `data-testid` attributes (e.g., `page.getByTestId('submit-btn')`).
- **Define Locators in Constructor:** Initialize all locators in the `constructor` of the Page Object class.

### 3. Assertions & Validation
- **Use Web-First Assertions:** Prefer `expect(locator).toBeVisible()`, `expect(locator).toHaveText()`, etc.
- **Avoid Manual Waits:** Do not use `page.waitForTimeout()`. Rely on auto-waiting and assertions.
- **Soft Assertions:** Use `expect.soft` for non-critical checks that shouldn't stop test execution immediately.
- **Custom Error Messages:** Add descriptive error messages to assertions where helpful.

### 4. Test Structure (`.spec.js`)
- **Descriptive Titles:** Use clear, descriptive titles for `test.describe` and `test` blocks.
- **Hooks:** Use `test.beforeEach` and `test.afterEach` for setup and teardown.
- **Clean Code:** Keep test files focused on test logic, delegating interaction details to Page Objects.

#### Example Test File (`tests/login.spec.js`):
```javascript
const { test, expect } = require('@playwright/test');
const { LoginPage } = require('../pages/LoginPage');

test.describe('Login Functionality', () => {
  let loginPage;

  test.beforeEach(async ({ page }) => {
    loginPage = new LoginPage(page);
    await loginPage.goto();
  });

  test('should login with valid credentials', async ({ page }) => {
    await loginPage.login('user', 'password');
    await expect(page).toHaveURL('https://example.com/dashboard');
  });
});
```

### 5. Coding Standards
- **Variables:** Use `const` for variable declarations.
- **Naming:** Use camelCase for variables and methods.
- **Comments:** Add brief comments explaining complex logic, but prefer self-documenting code.
- **Async/Await:** Ensure all Playwright actions are properly awaited.

### 6. Data Management
- **Test Data:** Separate test data from logic where possible (e.g., use fixtures or separate data files).
- **Dynamic Data:** Use dynamic data generation (like timestamps or UUIDs) for unique inputs to avoid conflicts.

---

## Python Standards (APPLY ONLY for .py files)
- **PEP 8:** Follow PEP 8 style guidelines.
- **Naming:** Use `snake_case` for functions and variables.
- **Type Hinting:** Use type hints where helpful.

## Java Standards (APPLY ONLY for .java files)
- **Naming:** Use `PascalCase` for classes and `camelCase` for methods/variables.
- **Conventions:** Follow standard Java coding conventions.
