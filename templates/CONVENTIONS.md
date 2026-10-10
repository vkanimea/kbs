# KBS Conventions — Read This Before Acting (V0.119)

**Why this file exists.** KBS is a long-lived knowledge system operated by *whatever
model the owner has wired*. Nothing here assumes a particular model, provider, or
vendor. These are the conventions a fresh model cannot infer from the files alone and
would otherwise have to rediscover by costly trial and error. Read this **first**, then
`agents.md`.

If a convention here ever conflicts with a specific session instruction, the session
instruction wins — but say so explicitly, because it means this file is stale.

---

## 1. System Repo vs Data Instance — the two-repo rule

There are **two** KBS repos, and confusing them is the single most common error:

| | System repo | Data instance |
|---|---|---|
| Path | `~/AIC/kbs` (source of truth) | `~/kbs` (synced copy + owner data) |
| Holds | `scripts/`, `templates/`, `docs/`, `VERSION` | wiki topics, INBOX, DECISIONS, ACTIONS, log |
| How to change | Edit **here** | Edited by the owner / by operations |
| Git | private GitHub (CI-validated) | private GitHub + offsite Gitea |

**The rule: fix upstream, sync down.** A *system-owned* file edited only in `~/kbs`
is overwritten by the next `kbs-sync.sh` run. So:

1. Edit system-owned files in `~/AIC/kbs`.
2. Run `scripts/kbs-sync.sh` to propagate down.
3. Never treat `~/kbs/scripts/…` as the place to make a system change.

**System-owned paths** are exactly the list in `scripts/kbs-sync.sh` (`SYSTEM_PATHS`) —
`templates/agents.md→agents.md`, `PROMPTS.md`, `VERSION`, `CHANGELOG.md`,
`templates/reference/*.md→reference/*.md`, and every file under `scripts/`. Everything
else in the instance (wiki, INBOX, DECISIONS, ACTIONS, FAILURES, SUCCESSES, log,
JOURNAL, model.conf) is **owner data** — never overwrite it from the system repo.

If the drift guard fires, check which repo you are in before assuming a false alarm.

---

## 2. Model wiring is configuration, not code

No script may hardcode a provider or model. Wiring resolves in this order:

1. **Environment** — `PI_PROVIDER` / `PI_MODEL` (per-invocation override)
2. **Instance config** — `$KBS/model.conf` (seed from `templates/model.conf.example`)
3. **Fail loudly** — with a message naming the fix; never silently default to one vendor

`scripts/model-config.sh` implements this (`kbs_resolve_model`). Scripts that need a
model source it and call it. Swapping models is then a one-line config edit, and the
absence of config is a clear error rather than a quiet assumption.

---

## 3. Output contracts are checked, not assumed

The pipeline (`Capture → Ingest → Build → Query → Improve`) depends on output *shape*,
not prose quality. When producing artefact for a stage, match the shape the pipeline
expects — do not invent a variant because it reads better:

- **Capture points:** `INBOX.md`, `CHAT_INBOX.md`, `FAILURES.md`, `SUCCESSES.md`.
- **Why vs what:** `DECISIONS.md` holds the *why*; `ACTIONS.md` holds dated commitments.
- **Wiki topics:** the typed-link format in `agents.md §Wiki Page Format`.
- **Close-out:** the 11-step routine in `reference/session-close.md`.

A model new to the system should **copy the existing shape** of a nearby entry rather
than derive a fresh one. If the shape seems wrong, propose a system change — do not
fork the format in one entry.

---

## 4. Close-out must flip status

The recurring defect: work is completed but its `ACTIONS.md` row is never moved to
`Done: Yes`, so it reports as open forever. When closing a session, for every action
touched, set `Done:` and fill `Outcome:` — completed work with an unclosed row is a
bug, not a rounding error. (Observed 2026-10-11: two rows — harbor01 store and
pre-backup sync — were done on 2026-10-08 but still counted as open.)

Installer **seed rows** (the `20XX-01-01` examples byte-identical to `templates/…`)
are *not* real commitments; they show up in due-counts only because the template
ships them. Retire one with `Done: N/A — installer seed example` if it causes noise.

---

## 5. Provenance and verification

- Assert only what the files support; when asked "where did you get that from",
  the answer must be a path, a line, or a captured entry — not recollection.
- Do not present a plausible reconstruction as fact. If a claim is inferred, mark it.
- Verify before asserting, especially about *this* system's structure (which repo,
  which path is authoritative) — the two-repo rule in §1 exists because this is
  easy to get wrong.

---

## 6. Posture

Passive by default (Activity Level 0): the owner approves all changes. Read-only
operations are always safe and never need approval. Destructive or outward-facing
actions (pushes, deletes, sends, edits to owner data) wait for explicit instruction.
Never change configuration to work around a problem unless asked.

---

## Changelog

- **V0.119 (2026-10-11)** — created. Names the two-repo rule, model wiring, output
  contracts, close-out status flipping, and provenance expectations, so a model new
  to KBS does not have to rediscover them by trial and error.
