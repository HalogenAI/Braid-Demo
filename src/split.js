'use strict';

// Splits a whole number of cents across n recipients as evenly as possible.
// The remainder is handed out one cent at a time to the first recipients,
// so the result always sums to exactly totalCents.
function splitAmount(totalCents, n) {
  if (!Number.isSafeInteger(totalCents) || totalCents < 0) {
    throw new RangeError('totalCents must be a non-negative integer');
  }
  if (!Number.isSafeInteger(n) || n < 1) {
    throw new RangeError('n must be a positive integer');
  }

  const base = Math.floor(totalCents / n);
  const remainder = totalCents % n;
  return Array.from({ length: n }, (_, i) => base + (i < remainder ? 1 : 0));
}

module.exports = { splitAmount };
