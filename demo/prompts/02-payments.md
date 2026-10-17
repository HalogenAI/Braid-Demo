# Session 2 — Allocation + webhook (Thread B)

You are implementing **payment allocation and webhook handling** for the same
marketplace service. Reasoning must be visible, not just code.

## Scope — edit ONLY these files
- `src/payments/allocate.js`
- `src/payments/webhook.js`
- `test/allocate.test.js`
- `test/webhook.test.js`  (create it)

Do **not** touch anything under `src/ledger/`. Treat the ledger's
`transfer(book, { from, to, amount, idempotencyKey })` as a fixed contract you
call — another engineer owns it.

## What to build

1. **Exact allocation.** Fix `allocate(totalCents, weights)` so the returned
   integer-cent parts **always sum to exactly `totalCents`** and the split is
   deterministic. The naive "round each share" loses or invents cents; that is
   unacceptable in a ledger.
2. **Idempotent, atomic webhook.** Harden `handleWebhook(ctx, event)` so that:
   - a re-delivered event (same `event.id`) does not pay anyone a second time;
   - each split is recorded via `ledger.transfer` with a **derived, stable
     idempotency key** (so the ledger's own idempotency and yours agree on a
     retry);
   - it is all-or-nothing: if any split cannot be applied, the event must not
     leave a partially-paid state.

Add tests in `test/allocate.test.js` and `test/webhook.test.js` proving: parts
always sum to the total (include an amount that does not divide evenly, e.g.
`1000` across weights `[1,1,1]`); a duplicate event is a no-op the second time;
a mid-way failure applies nothing. Run `npm test` and make it pass.

## Make your judgment visible (Braid is capturing this session)
- Begin each distinct approach with `ATTEMPT <n>`.
- Reject approaches explicitly: `DECISION: rejected` + the concrete reason.
- Lock in the design with one line:
  `DESIGN_DECISION: choice=<what> | alternatives=<what you weighed> | reason=<why this one>`
- Finish with exactly one `VERDICT:` line.

Call out the rounding choice specifically (e.g. largest-remainder vs. give the
remainder to the first/last recipient) and the idempotency-key choice
(client-supplied vs. derived from the event) — these are the judgment calls.

Stop after the `VERDICT:` line. Do not open anything for review yet.
