/**
 * tests/unit/utils.test.js
 *
 * Unit tests for the pure utility functions in src/utils.js.
 *
 * Uses Node.js built-in test runner (node:test) — no extra dependencies.
 * Run with:  npm run test:unit
 *
 * In CI, a JUnit XML report is also generated for dorny/test-reporter to
 * publish as GitHub Check annotations on the pull request.
 */

'use strict';

const { test, describe } = require('node:test');
const assert = require('node:assert/strict');
const { parseCartCount, formatPrice } = require('../../src/utils');

// ── parseCartCount ────────────────────────────────────────────────────────────
describe('parseCartCount', () => {

    test('returns 0 for a "0" string', () => {
        assert.equal(parseCartCount('0'), 0);
    });

    test('parses a positive integer string correctly', () => {
        assert.equal(parseCartCount('3'), 3);
    });

    test('parses a multi-digit integer string correctly', () => {
        assert.equal(parseCartCount('12'), 12);
    });

    test('trims leading and trailing whitespace before parsing', () => {
        assert.equal(parseCartCount('  5  '), 5);
    });

    test('returns 0 for an empty string', () => {
        assert.equal(parseCartCount(''), 0);
    });

    test('returns 0 for a non-numeric string', () => {
        assert.equal(parseCartCount('abc'), 0);
    });

    test('returns 0 for a negative value', () => {
        assert.equal(parseCartCount('-1'), 0);
    });

    test('accepts a numeric argument directly', () => {
        assert.equal(parseCartCount(7), 7);
    });

});

// ── formatPrice ───────────────────────────────────────────────────────────────
describe('formatPrice', () => {

    test('formats a whole number to 2 decimal places', () => {
        assert.equal(formatPrice(19), '19.00');
    });

    test('formats a float with 1 decimal to 2 decimal places', () => {
        assert.equal(formatPrice(19.9), '19.90');
    });

    test('formats a float with 2 decimals unchanged', () => {
        assert.equal(formatPrice(199.99), '199.99');
    });

    test('formats a string numeric value', () => {
        assert.equal(formatPrice('29.50'), '29.50');
    });

    test('returns "0.00" for a non-numeric string', () => {
        assert.equal(formatPrice('bad'), '0.00');
    });

    test('returns "0.00" for an empty string', () => {
        assert.equal(formatPrice(''), '0.00');
    });

});
