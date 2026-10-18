#!/usr/bin/env bash
#
# Braid VC demo — add the payments-ledger scenario into an EXISTING braid repo
# (e.g. ~/braid-demo, which already has Braid set up). Unlike setup.sh this does
# NOT run `git init`; it creates a feature branch, writes the naive baseline,
# and commits it, so the agent sessions have something real and in-scope to work
# on while leaving your existing files (money.js etc.) untouched.
#
# Run it from INSIDE the repo:   cd ~/braid-demo && bash /path/to/add-ledger.sh
set -euo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "not inside a git repository — cd into your braid-demo repo first" >&2; exit 1; }
if [ -n "$(git status --porcelain)" ]; then
  echo "working tree is dirty — commit or stash first, then re-run" >&2; exit 1; fi
if [ -e src/ledger/engine.js ]; then
  echo "src/ledger already exists — remove it or use a clean repo" >&2; exit 1; fi

git switch -c feat/payments-ledger

mkdir -p src/ledger src/payments test

[ -f package.json ] || cat > package.json <<'EOF'
{
  "name": "braid-demo",
  "version": "0.0.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
EOF

cat > src/ledger/engine.js <<'EOF'
'use strict';
// In-memory double-entry ledger.
// BASELINE (naive): no idempotency, no concurrency safety, no validation.
function createBook(initial = {}) { return { balances: { ...initial } }; }
function balance(book, account) { return book.balances[account] ?? 0; }
async function transfer(book, { from, to, amount }) {
  book.balances[from] = (book.balances[from] ?? 0) - amount;
  book.balances[to] = (book.balances[to] ?? 0) + amount;
  return { from, to, amount };
}
module.exports = { createBook, balance, transfer };
EOF

cat > src/payments/allocate.js <<'EOF'
'use strict';
// Split an amount (integer cents) across weighted recipients.
// BASELINE (naive): rounds each share independently, so parts need not sum to
// the total — inventing or destroying cents.
function allocate(totalCents, weights) {
  const sum = weights.reduce((a, b) => a + b, 0);
  return weights.map((w) => Math.round((totalCents * w) / sum));
}
module.exports = { allocate };
EOF

cat > src/payments/webhook.js <<'EOF'
'use strict';
// Handle a payment-provider webhook: allocate the captured amount across
// sellers and record a transfer per split from the platform float.
// BASELINE (naive): not idempotent (replay pays twice) and not atomic
// (a mid-way failure leaves splits half-applied).
async function handleWebhook(ctx, event) {
  const { book, ledger, allocate } = ctx;
  const parts = allocate(event.amountCents, event.sellers.map((s) => s.weight));
  for (let i = 0; i < event.sellers.length; i++) {
    await ledger.transfer(book, {
      from: 'platform_float', to: event.sellers[i].account, amount: parts[i],
    });
  }
  return { eventId: event.id, parts };
}
module.exports = { handleWebhook };
EOF

cat > test/ledger-engine.test.js <<'EOF'
'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { createBook, balance, transfer } = require('../src/ledger/engine');
test('a single transfer moves money', async () => {
  const book = createBook({ alice: 100, bob: 0 });
  await transfer(book, { from: 'alice', to: 'bob', amount: 40 });
  assert.equal(balance(book, 'alice'), 60);
  assert.equal(balance(book, 'bob'), 40);
});
EOF

cat > test/allocate.test.js <<'EOF'
'use strict';
const { test } = require('node:test');
const assert = require('node:assert');
const { allocate } = require('../src/payments/allocate');
test('an evenly divisible amount splits cleanly', () => {
  assert.deepEqual(allocate(900, [1, 1, 1]), [300, 300, 300]);
});
EOF

git add -A
git commit -q -m "baseline: naive marketplace payments ledger"

echo
echo "✓ ledger scenario added on branch: feat/payments-ledger"
echo "  run the baseline:  node --test     (should pass)"
echo "  next: run the three agent sessions, committing between each,"
echo "        then braid intent -> review -> push (bot) -> ship."
