# Cypress Installation Guide

Follow these steps to install and set up Cypress for your project.

---

## 1. Prerequisites
- Ensure you have [Node.js](https://nodejs.org/) (version 14 or above) and npm installed.
- (Optional) Initialize your project with npm if you haven't already:
  ```sh
  npm init -y
  ```

---

## 2. Install Cypress
Run the following command in your project root directory:
```sh
npm install cypress --save-dev
```

---

## 3. Open Cypress for the First Time
After installation, open Cypress using:
```sh
npx cypress open
```
This will create a `cypress/` folder and a default configuration file in your project.

---

## 4. Run Cypress Tests
To run tests in headless mode (useful for CI/CD):
```sh
npx cypress run
```

---

## 5. Additional Resources
- [Cypress Documentation](https://docs.cypress.io/)
- [Cypress GitHub](https://github.com/cypress-io/cypress)

---

**Troubleshooting:**
- If you encounter issues, ensure your Node.js and npm versions are up to date.
- Restart your terminal after installation if Cypress is not recognized.
