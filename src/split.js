'use strict';

/**
 * Split totalCents across n recipients as evenly as possible.
 * The first (totalCents % n) recipients receive one extra cent.
 */
function splitAmount(totalCents, n) {
  if (!Number.isInteger(totalCents) || totalCents < 0) {
    throw new RangeError('totalCents must be a non-negative integer');
  }
  if (!Number.isInteger(n) || n < 1) {
    throw new RangeError('n must be a positive integer');
  }
  const base = Math.floor(totalCents / n);
  const remainder = totalCents % n;
  return Array.from({ length: n }, (_, i) => base + (i < remainder ? 1 : 0));
}

module.exports = { splitAmount };
