# Session 3 — Review challenge, open for review, ship

Both workstreams are implemented and `node --test` is green. You are now acting
on **reviewer feedback**, then opening the combined work for review. Write your
decisions down as labeled lines — the back-and-forth is the part a human
reviewer most wants kept.

## The reviewer's challenge (respond to this directly)
> "Per-account pessimistic locking is correct, but every marketplace payout
> debits the single `platform_float` account, so *every* transfer now serializes
> through one lock. Under load that's a throughput cliff. Either justify keeping
> it as-is for now, or revise — and whichever you choose, the decision has to be
> on the record, not just in the code."

Engage with it directly. You may keep the current design or revise it (e.g.
lock striping, a sharded float, or batching payouts), but you must:
- `ATTEMPT <n>` the options you consider;
- `DECISION: rejected <what and why>` for anything you discard, with the real
  reason (e.g. "sharding the float breaks the single-balance invariant the
  ledger guarantees");
- land on one line `DESIGN_DECISION: choice=<what> | alternatives=<what you weighed> | rationale=<why>` — including, if you defer the optimization, the explicit tradeoff ("correctness now, documented scaling path") and what would trigger revisiting it.

If you change code, stay within the already-established scopes and keep
`node --test` green. Finish with one `VERDICT:` line.

## Then open it for review and create the pull request
When the verdict is in, do the following (these will trigger Braid's own agent
skills — let them run):

1. Open the branch's captured work for review and reconstruct the intent:
   > open this branch for review with braid intent

2. Push the branch and create a pull request, then link the braid to it:
   > push the branch, create the pull request, and push the braid so the intent
   > shows up on the PR

Report the braid id and the pull request URL when done.
