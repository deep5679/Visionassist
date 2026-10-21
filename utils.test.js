// Unit tests for utils.js, using Node's built-in test runner (no npm install needed).
// Run with: node --test
const test = require('node:test');
const assert = require('node:assert');
const { cleanText, clampRate } = require('./utils.js');

test('cleanText returns empty string for non-string input', () => {
  assert.strictEqual(cleanText(undefined), '');
  assert.strictEqual(cleanText(null), '');
  assert.strictEqual(cleanText(123), '');
});

test('cleanText converts Windows line endings to \\n', () => {
  assert.strictEqual(cleanText('a\r\nb\rc'), 'a\nb\nc');
});

test('cleanText collapses repeated spaces and tabs', () => {
  assert.strictEqual(cleanText('hello \t  world'), 'hello world');
});

test('cleanText trims each line and the whole text', () => {
  assert.strictEqual(cleanText('  one  \n  two  '), 'one\ntwo');
});

test('cleanText limits blank lines to one', () => {
  assert.strictEqual(cleanText('a\n\n\n\n\nb'), 'a\n\nb');
});

test('clampRate keeps valid values unchanged', () => {
  assert.strictEqual(clampRate(1), 1);
  assert.strictEqual(clampRate('1.5'), 1.5);
});

test('clampRate limits values to the 0.5 - 2 range', () => {
  assert.strictEqual(clampRate(5), 2);
  assert.strictEqual(clampRate(0.1), 0.5);
});

test('clampRate falls back to 1 for non-numeric input', () => {
  assert.strictEqual(clampRate('abc'), 1);
  assert.strictEqual(clampRate(undefined), 1);
});
