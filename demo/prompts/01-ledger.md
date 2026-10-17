# Session 1 — Ledger engine (Thread A)

You are implementing the **double-entry ledger engine** for a marketplace
payments service. This is a demo of engineering judgment, so your reasoning
must be visible, not just your code.

## Scope — edit ONLY these files
- `src/ledger/engine.js`
- `test/ledger-engine.test.js`

Do **not** touch anything under `src/payments/`. That is another engineer's
workstream and the scopes must stay disjoint.

## What to build
Harden `transfer(book, { from, to, amount, idempotencyKey })` so it is correct
under the conditions a real ledger faces:

1. **Idempotency.** A retried transfer with the same `idempotencyKey` must
   return the original result and apply the money exactly once. The same key
   replayed with a *different* amount is a conflict and must throw — never a
   silent no-op.
2. **Concurrency safety.** Two transfers that touch overlapping accounts may
   run concurrently (e.g. `A->B` and `B->A` at the same time). Serialize access
   per account so balances never interleave, and make sure your locking cannot
   deadlock.
3. **Invariants.** Reject non-positive amounts. Never let the sum of all
   balances change as a result of a transfer (money is conserved).

Add tests in `test/ledger-engine.test.js` that prove: idempotent replay applies
once; a same-key/different-amount replay throws; concurrent `A->B` and `B->A`
both complete without deadlock and conserve the total; a non-positive amount is
rejected. Run `npm test` and make it pass.

## Make your judgment visible (Braid is capturing this session)
As you work, narrate the decisions in your normal output:
- Begin each distinct approach with `ATTEMPT <n>`.
- When you reject an approach, write `DECISION: rejected` and the concrete
  reason (name the failure mode — e.g. the deadlock, the TOCTOU race).
- When you lock in the design, write one line:
  `DESIGN_DECISION: choice=<what> | alternatives=<what you weighed> | reason=<why this one>`
- Finish with exactly one `VERDICT:` line summarizing the state and test result.

Think about the lock-ordering trap specifically: acquiring "from then to" is the
obvious move and it deadlocks under cross transfers. Show that you saw it.

Stop after the `VERDICT:` line. Do not open anything for review yet — the other
workstream is still in flight.
