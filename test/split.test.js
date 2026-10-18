'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { splitAmount } = require('../src/split');

const sum = (a) => a.reduce((x, y) => x + y, 0);

test('divides evenly', () => {
  assert.deepEqual(splitAmount(100, 4), [25, 25, 25, 25]);
});

test('100 across 3 loses no cent', () => {
  const r = splitAmount(100, 3);
  assert.deepEqual(r, [34, 33, 33]);
  assert.equal(sum(r), 100);
});

test('total smaller than n', () => {
  assert.deepEqual(splitAmount(2, 5), [1, 1, 0, 0, 0]);
});

test('zero total and single recipient', () => {
  assert.deepEqual(splitAmount(0, 3), [0, 0, 0]);
  assert.deepEqual(splitAmount(99, 1), [99]);
});

test('always sums to total and differs by at most 1', () => {
  for (let total = 0; total <= 200; total++) {
    for (let n = 1; n <= 12; n++) {
      const r = splitAmount(total, n);
      assert.equal(r.length, n);
      assert.equal(sum(r), total);
      assert.ok(Math.max(...r) - Math.min(...r) <= 1);
    }
  }
});

test('rejects invalid input', () => {
  assert.throws(() => splitAmount(10, 0), RangeError);
  assert.throws(() => splitAmount(10.5, 2), RangeError);
  assert.throws(() => splitAmount(-1, 2), RangeError);
});
