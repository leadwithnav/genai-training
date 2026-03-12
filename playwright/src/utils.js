/**
 * src/utils.js
 *
 * Pure utility functions shared across Page Objects and test suites.
 * Keeping these isolated makes them easily unit-testable with node:test
 * — no browser, no Playwright, no network required.
 */

'use strict';

/**
 * Parses the integer cart count from the text content of the #cart-count badge.
 * Returns 0 for any non-numeric, negative, or empty input.
 *
 * @param {string|number} text  Raw text from the DOM element (e.g. "3", " 0 ")
 * @returns {number}            A non-negative integer, defaults to 0 on error
 *
 * @example
 * parseCartCount('3')    // → 3
 * parseCartCount(' 0 ')  // → 0
 * parseCartCount('')     // → 0
 * parseCartCount('abc')  // → 0
 */
function parseCartCount(text) {
    const n = parseInt(String(text).trim(), 10);
    return Number.isFinite(n) && n >= 0 ? n : 0;
}

/**
 * Formats a price value (number or numeric string) to exactly 2 decimal places.
 * Returns '0.00' for any non-numeric input.
 *
 * @param {number|string} value  Raw price value (e.g. 19, 19.9, "199.00")
 * @returns {string}             Formatted string, e.g. "19.00", "199.00"
 *
 * @example
 * formatPrice(19)       // → '19.00'
 * formatPrice(19.9)     // → '19.90'
 * formatPrice('bad')    // → '0.00'
 */
function formatPrice(value) {
    const n = parseFloat(String(value));
    return Number.isFinite(n) ? n.toFixed(2) : '0.00';
}

module.exports = { parseCartCount, formatPrice };
