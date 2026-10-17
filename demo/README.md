# Braid Demo — Playbook

**Audience:** investor. **Length:** ~7 minutes live. **Thesis you're proving:**
*AI writes the code; the judgment behind it evaporates. Braid is the work layer
that captures the reasoning as the agent works, reconstructs the intent, and
puts it beside the diff on the pull request — signed.*

The scenario is a **marketplace payments ledger**. The punchline is that the
final diff is ~60 lines and looks boring, while the judgment behind it —
rejected deadlock-prone locking, a rounding scheme that can't lose a cent,
idempotent webhook replay, and a reviewer challenge about throughput — is the
actual product. Braid makes that judgment a first-class, reviewable,
auditable artifact.

---

## 0. One-time prerequisites (do these BEFORE the VC is in the room)

Your installed Braid is **v0.2.0-alpha.13** (daemon + hosted-server
architecture — there is no `wrap`, no `attach`, no `promote`, and no separate
orchestrator/intent binaries). Capture is automatic once the Claude hooks are
installed.

```sh
braid auth login --host https://api.braidkit.io
braid hooks install claude
braid doctor
```

`braid doctor` must be clean (the daemon green, harness green). Then, for the
pull-request moment:

- The demo repo must live on **GitHub** in an org/account where the **Braid
  GitHub App is installed** (that App is how `braid bot` posts). Create the
  repo and install the App ahead of time.
- Enable the bot so pushes publish the intent projection to the PR:

```sh
braid bot enable --host https://api.braidkit.io
braid bot status
```

Scaffold the demo repo and do a **full dry run** the day before — agents are
non-deterministic; you want to have seen the intent it produces.

```sh
bash demo/setup.sh                 # creates ~/braid-vc-demo
cd ~/braid-vc-demo && npm test     # 2 passing baseline tests
```

Point the repo's `origin` at your prepared GitHub repo:

```sh
git remote add origin git@github.com:<your-org>/braid-vc-demo.git
```

---

## 1. The command flow (what you'll actually run)

Capture is passive — you just run Claude in the repo and the daemon records it.
Run the three sessions **in order**, pasting each prompt file into `claude`:

```sh
cd ~/braid-vc-demo

claude "$(cat /path/to/demo/prompts/01-ledger.md)"      # Thread A: ledger
claude "$(cat /path/to/demo/prompts/02-payments.md)"    # Thread B: payments
```

After the two build sessions, show the captures, then run the review/ship
session which drives Braid via its skills:

```sh
braid status                                            # two captured sessions
claude "$(cat /path/to/demo/prompts/03-review-and-ship.md)"
```

Session 3 ends by invoking, in the agent's own words, `braid intent` (opens the
Review UI) and `braid push` (lands the intent on the PR). Finish with:

```sh
braid status <braid_id>     # authoritative state: threads, verdict
braid replay <braid_id>     # signed provenance from the event log
braid ship   <braid_id>     # merge, sign, finalize (irreversible)
```

> Confirm exact flags once with `braid intent --help`, `braid review --help`,
> `braid ship --help` on your machine — verbs are stable, flags I'd verify live.

---

## 2. Beat-by-beat script (with talking points)

**Beat 1 — Frame it (30s, no terminal).**
"Your engineers now ship code an agent wrote. The diff tells you *what*
changed. It never tells you *why* — which approaches were tried and rejected,
what tradeoff was made, what the author was worried about. That reasoning is
where all the risk lives, and today it's lost the moment the session ends.
Braid captures it."

**Beat 2 — The boring baseline (20s).**
`cat src/ledger/engine.js` — "Here's a naive payments ledger. Two passing
tests. Looks fine. It's wrong in three ways that matter, and a human reviewer
staring at a green check wouldn't catch them."

**Beat 3 — Agent 1, judgment in the open (90s).**
Run the ledger session. Narrate as the markers scroll by: "Watch — it *tries*
the obvious lock order, `ATTEMPT 1`, then catches itself: `DECISION: rejected`,
that deadlocks when two transfers cross. It lands a `DESIGN_DECISION` with the
alternatives it weighed. **This is the senior-engineer reasoning that normally
exists only in someone's head for about ten minutes.** Braid is recording it as
structured work."

**Beat 4 — Agent 2, a second disjoint workstream (60s).**
Run the payments session. "Different engineer, different files — allocation and
webhooks. Same thing: it rejects the rounding that loses a cent, picks
largest-remainder, and explains why. Two independent threads of work."

**Beat 5 — `braid status`: the braid (30s).**
"Braid wove those two sessions into one unit of work — disjoint scopes, each
with its own captured reasoning and verdict. One reviewable thing, not two
orphaned chat logs."

**Beat 6 — The back-and-forth (90s — the emotional core).**
Run the review/ship session. "Now a reviewer pushes back: that lock serializes
every payout through the float account — a throughput cliff. Watch the agent
*argue it out* — weigh sharding, reject it because it breaks the ledger's
single-balance invariant, and land on 'correct now, here's the documented
scaling path and the trigger to revisit.' **That exchange — the challenge and
the defense — is exactly what gets lost in AI development, and it's the most
valuable thing in the room.** Braid keeps it."

**Beat 7 — Skills (20s, point it out as it happens).**
"Notice I didn't run Braid commands by hand there. I told the agent 'open this
for review' and 'put the intent on the PR' — Braid ships **skills** the agent
loads, so it drives the whole review workflow itself. Braid meets the agent
where it already is."

**Beat 8 — The money shot: the PR (90s).**
Open the GitHub pull request. "Here's the diff — 60 lines, unremarkable. And
here—" scroll to the **Braid bot comment** "—is the reconstructed intent, posted
automatically beside the diff by Braid: every rejected approach, every design
decision, the reviewer's challenge and the resolution. **The reviewer approves
with the full judgment in front of them, not a shrug.** That's Braid."

**Beat 9 — Trust / audit (20s).**
`braid replay <braid_id>` — "And it's not marketing copy on a comment — it's
signed provenance from an event log. For a regulated buyer, this is the audit
trail for AI-authored change: who decided what, why, verifiably."

**Close (15s).**
"Every team is about to have agents writing most of their code. The bottleneck
becomes trust and review. Braid is the layer that makes AI-written code
reviewable at the speed it's written."

---

## 3. Where each thing you asked for shows up

| You wanted | Where it lands in the demo |
| --- | --- |
| Complex code where Braid adds value **on judgment** | Beats 2–4: tiny diff, deep reasoning (deadlock, rounding, idempotency) |
| **Back-and-forth with agents** | Beat 6: reviewer challenge → agent defends/revises on the record |
| Value of **Braid skills** | Beat 7: the agent runs `braid intent`/`braid push` itself via skills |
| **Braid bot** | Beat 8: the intent projection auto-posted on the PR via the GitHub App |

---

## 4. Fallbacks (have these ready — agents are non-deterministic)

- **An agent doesn't emit clean markers / wanders.** You did a dry run, so fall
  back to the recording from that run: `braid status` and the Review UI still
  show the captured session. The markers are a nudge, not a requirement — Braid
  captures the whole session regardless.
- **No GitHub App / PR not available at demo time.** Skip Beat 8's PR and show
  the same reconstructed intent in the **Review UI** that `braid intent` opens,
  plus `braid bot status` to explain where it would post. Narrate: "in CI this
  lands on the PR automatically."
- **Live `claude` is slow or offline.** Run the three sessions during your dry
  run and present against the already-captured braid: open with `braid status`,
  walk the Review UI, open the pre-made PR. The story is identical; only the
  typing is pre-done.
- **`braid ship` is irreversible** — only run it if you're genuinely closing the
  braid. For a repeatable demo, stop at `braid replay` and leave `ship` as "and
  the final step merges, signs, and finalizes."

---

## 5. Reset between runs

```sh
rm -rf ~/braid-vc-demo
bash demo/setup.sh
```

(Use a fresh GitHub branch per practice run so the PR/bot comment is clean.)
