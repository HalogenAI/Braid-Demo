# Session 1 — Ledger engine (Thread A)

You are implementing the **double-entry ledger engine** for a marketplace
payments service. This is a demo of engineering judgment, so write your
implementation choices down as you go — don't just leave the final code.

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
rejected. Run `node --test` and make it pass.

## Log your implementation choices (self-documenting work log)
As you implement, print short labeled status lines so the change documents
itself:
- `ATTEMPT <n>` before each distinct approach you try.
- `DECISION: rejected <what and why>` whenever you switch approach — name the
  concrete failure mode (for example the deadlock from locking "from then to",
  or a check-then-write race).
- one line `DESIGN_DECISION: choice=<what> | alternatives=<what you weighed> | rationale=<why this one>` when you settle the final approach.
- one final `VERDICT:` line summarizing the state and the test result.

The lock-ordering trap is the interesting one: acquiring "from then to" is the
obvious move and it deadlocks under cross transfers — show that you caught it.

Stop after the `VERDICT:` line. Do not open anything for review yet — the other
workstream is still in flight.
