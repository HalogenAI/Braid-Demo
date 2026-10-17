#!/usr/bin/env bash
#
# Braid VC demo — scaffold.
# Creates a small marketplace-payments ledger with a DELIBERATELY NAIVE baseline.
# The baseline passes a couple of easy tests but silently mishandles the three
# traps the demo is about: lock-ordering deadlock, rounding that loses/creates
# cents, and non-idempotent webhook replay. The coding agents fix these and —
# crucially — record WHY, which is what Braid captures.
#
# Usage:   bash setup.sh [target-dir]
# Default: ~/braid-vc-demo
set -euo pipefail

DEST="${1:-$HOME/braid-vc-demo}"
if [ -e "$DEST" ]; then
  echo "refusing to overwrite existing $DEST — pass a fresh path or remove it" >&2
  exit 1
fi

mkdir -p "$DEST"/src/ledger "$DEST"/src/payments "$DEST"/test
cd "$DEST"

cat > package.json <<'EOF'
{
  "name": "braid-vc-demo",
  "version": "0.0.0",
  "private": true,
  "description": "Marketplace payments ledger — Braid judgment demo",
  "scripts": {
    "test": "node --test"
  }
}
EOF

# ---- Thread A scope: src/ledger/** ---------------------------------------
cat > src/ledger/engine.js <<'EOF'
'use strict';
// In-memory double-entry ledger.
//
// BASELINE (naive): no idempotency, no concurrency safety, no validation.
// A transfer debits `from` and credits `to`. That's it. It looks fine in a
// single-threaded test and is wrong the moment money, retries or concurrency
// are real.

function createBook(initial = {}) {
  return { balances: { ...initial } };
}

function balance(book, account) {
  return book.balances[account] ?? 0;
}

async function transfer(book, { from, to, amount }) {
  book.balances[from] = (book.balances[from] ?? 0) - amount;
  book.balances[to] = (book.balances[to] ?? 0) + amount;
  return { from, to, amount };
}

module.exports = { createBook, balance, transfer };
EOF

# ---- Thread B scope: src/payments/** -------------------------------------
cat > src/payments/allocate.js <<'EOF'
'use strict';
// Split an amount (in integer cents) across weighted recipients.
//
// BASELINE (naive): round each share independently. The rounded parts do not
// have to add up to the original total, so this invents or destroys cents —
// a cardinal sin in a ledger.

function allocate(totalCents, weights) {
  const sum = weights.reduce((a, b) => a + b, 0);
  return weights.map((w) => Math.round((totalCents * w) / sum));
}

module.exports = { allocate };
EOF

cat > src/payments/webhook.js <<'EOF'
'use strict';
// Handle a payment-provider webhook: allocate the captured amount across the
// sellers and record a transfer for each split out of the platform float.
//
// BASELINE (naive): not idempotent (a re-delivered event pays everyone twice)
// and not atomic (if split #3 fails, splits #1 and #2 have already moved).

async function handleWebhook(ctx, event) {
  const { book, ledger, allocate } = ctx;
  const parts = allocate(event.amountCents, event.sellers.map((s) => s.weight));
  for (let i = 0; i < event.sellers.length; i++) {
    await ledger.transfer(book, {
      from: 'platform_float',
      to: event.sellers[i].account,
      amount: parts[i],
    });
  }
  return { eventId: event.id, parts };
}

module.exports = { handleWebhook };
EOF

# ---- Baseline tests (green at setup; the easy cases only) -----------------
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

cat > README.md <<'EOF'
# braid-vc-demo — marketplace payments ledger

A deliberately small service with a naive baseline. Two disjoint workstreams:

- `src/ledger/**`   — the double-entry transfer engine (concurrency, idempotency)
- `src/payments/**` — allocation (rounding) + idempotent webhook handling

The baseline passes the two easy tests in `test/`. It mishandles every case
that matters. Fixing it well is a matter of judgment, not typing — which is the
point of this demo.
EOF

cat > .gitignore <<'EOF'
node_modules/
EOF

git init -q
git add -A
git commit -q -m "baseline: naive marketplace payments ledger"
git switch -q -c feature/payments-ledger

echo
echo "✓ demo repo ready at: $DEST"
echo "  baseline test:   (cd \"$DEST\" && npm test)   # 2 passing"
echo "  working branch:  feature/payments-ledger"
echo
echo "Next: run the three agent sessions from demo/prompts/ in THIS repo,"
echo "then drive braid intent -> review -> push (bot) -> ship."
