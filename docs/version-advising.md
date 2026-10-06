# Advising a New KBS Version (release runbook)

When a new KBS system version is announced — especially one that adds features
like **goal-loop** or **graphify-index** — a data instance should be updated and
*verified* before you advise anyone or treat it as healthy. This runbook is the
checklist.

## Architecture reminder (why this matters)

| Repo | Role | Contents |
|---|---|---|
| system repo (`kbs`) | **system** (public) | `scripts/`, `docs/`, `examples/`, installers, `VERSION`, `CHANGELOG.md` |
| data repo (`kbs-data`) | **data** (private) | real knowledge (`kb/`, `INBOX.md`, journals) **plus an installed copy** of the system files |

System files in the data repo are refreshed on install/upgrade; user files are
never overwritten. So `scripts/`, `CHANGELOG.md`, `VERSION`, and `examples/` in a
data instance mirror upstream. See *The Harness Layer* in
[architecture.md](architecture.md) and the System/Data separation in
[deployment.md](deployment.md).

## Procedure

1. **Sync system files** into the data instance — use `scripts/kbs-sync.sh` (or
   run `install.sh`, or the entrypoint refresh for Docker). Confirm the new
   version landed:
   ```bash
   cd ~/kbs && scripts/kbs-sync.sh --check && cat VERSION
   ```
   `kbs-sync.sh --check` exits non-zero when the instance's system files differ
   from the system repo, so it doubles as a drift alarm. `VERSION` should read
   the new release (e.g. `0.116.2`), and `CHANGELOG.md` should carry the release
   heading.

2. **Activate & verify every new feature before advising it** — don't trust the
   changelog. Two current examples:
   - **goal-loop**: run the self-test example and demand exit `0`:
     ```bash
     ./scripts/goal-loop.sh examples/goal.md
     ```
     Expect `GOAL MET: validation passed ...` and exit `0`. Non-zero exit = the
     wrapper or its model wiring is broken.
   - **graphify-index**: index a real corpus and demand a non-empty graph:
     ```bash
     ./scripts/graphify-index.sh <project> <code_dir> --wiki
     ```
     Expect exit `0`, a non-empty `kb/projects/<project>/graphs/graph.json`, and
     (with `--wiki`) a populated `wiki/graph/` dir.

2b. **Register any new custom style in the instance's `SYSTEM.md`.** `SYSTEM.md` is
   **user-owned** — `kbs-sync.sh` never overwrites it — so a style added to the system
   repo's `templates/SYSTEM.md` reaches *fresh installs only*. An existing instance must
   paste the style block into its own `SYSTEM.md §Style Registry` by hand. V0.117 added
   the `Learn/Lesson` style this way: after syncing, confirm the instance's `SYSTEM.md`
   contains `name: Learn/Lesson` before advising `Teach me [KB]:`
   (`grep -n "Learn/Lesson" SYSTEM.md`). The operation (`reference/learning.md`) *is*
   synced normally; only the registry entry needs the manual paste.

3. **If a feature is broken on activation** — treat the fix as a **patch**, not a
   feature bump (matching this project's convention, e.g. V0.116.1, V0.116.2):
   - fix the wrapped script, add a patch note to `CHANGELOG.md`, bump `VERSION`
     to the next patch (`0.116.2`), commit.
   - **Fix it in the system repo first, then re-sync down.** A fix committed only
     in the data instance is a fork — the next sync will either overwrite it or
     silently lose it. A known example: `V0.116.2` fixed `graphify-index.sh`,
     which shipped with `--mode standard` (invalid on graphify ≥0.9) and no
     code-only fallback.

4. **Update examples to match the verified reality** so future advising is
   reproducible:
   - `examples/goal.md` — self-test goal with a passing gate.
   - `examples/graphify.md` — verified run output + behavior notes.
   Keep the live-output blocks timestamped so they read as evidence, not promises.

5. **Sign-off** — only after a feature activates cleanly does the version get
   advised as "good to upgrade to". If it cannot be verified here (no LLM key,
   missing binary), say so explicitly and mark `verify-before-shipping`.

## Pitfalls

- **`--mode standard` is dead** for graphify ≥0.9 (only `deep`). Any wrapper
  defaulting to `standard` silently fails to build a graph — always check for a
  non-empty `graph.json`, not just exit code.
- **No LLM key ≠ broken.** graphify's code path is deterministic and needs no key;
  only doc/image extraction and community naming need one. Use `--code-only`.
- **Version semantics:** wording/plumbing fixes are *patches* (feature `.N` stays),
  not new feature versions. Don't invent `0.117` for a wording fix.
- **Pipeline exit codes:** when verifying with `cmd 2>&1 | tail`, `$?` reflects
  `tail`, not `cmd`. Check the script's own `GOAL MET` / `ERROR:` lines.
- **Never fix system files only in the data instance.** See
  [deployment.md](deployment.md) → *System vs data* and
  [architecture.md](architecture.md) → *The Harness Layer*. The data repo's
  system-file copy is downstream of the system repo, not a second source of truth.

## Verification (proves this runbook worked)

- `scripts/kbs-sync.sh --check` exits `0` (instance's system files match the system repo).
- `cat VERSION` shows the expected release (or a patch on it).
- `goal-loop.sh examples/goal.md` exits `0` with `GOAL MET`.
- `graphify-index.sh` exits `0` and `graph.json` is non-empty.
- `examples/goal.md` and `examples/graphify.md` are present and current.
