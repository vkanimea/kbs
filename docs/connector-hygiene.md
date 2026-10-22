# Connector Hygiene — ingestion that can silently stop is the failure mode

A knowledge base is only as good as its freshest data. Every mechanism here
exists because of a specific silent failure that already happened once. This
doc is the operational detail behind CONVENTIONS §8.

## 1. Incremental pulls, stamped

Connectors pull **only what is new since the last run**, stamped with the
current date/time. First run backfills; every run after is a delta. This keeps
ingest cheap, makes the date stamp honest, and gives the freshness watchdog a
signal it can measure.

## 2. Read-only credentials — one scoped exception

- **Ingest connectors are READ-ONLY.** A connector with write access can
  destroy the source it indexes. Read-only tokens only, one scope per source.
- **The backup connector is the one exception** (it must push to the offsite
  git server). Scope-limit instead: push-only credentials, HTTPS-only, served
  via `scripts/git-credential-env.sh` — never a blanket token.

Audit record:

| Date | Scope | Result |
|---|---|---|
| 2026-10-19 | `scripts/*.sh`, `scripts/*.py` — credential usage review | Ingest paths (hourly-ingest, youtube-ingest, rag-index, topic-index) hold no source credentials at all; network credentials appear only in the backup/push path (`git-credential-env.sh`, `nightly-backup.sh`, `backup-verify.sh`, `backup-catchup.sh`), consistent with the scoped-exception rule. No changes required. |

## 3. Connectors rot silently — watch them

Rot is normal: API keys rotate, permissions change, routes stop existing,
upgrades drop cron lines. The rule from the 2026-10-12 backup incident:
**do not monitor the schedule ("did cron fire?"), monitor the outcome ("did
data arrive / did the push land?").**

Two tools, one per layer:

- `scripts/ingest-freshness.sh` — watchdog for the ingest connectors
  (hourly-ingest cadence in `log.md`, backup cadence in `backup.log`, per-job
  catchup stamps in `~/.local/state/kbs-backup/`). WARN + exit 1 on any
  connector past its interval.
- `backup-verify.sh --assert / --drill` — outcome-side verification for the
  backup path (remote ref match + recovery drill). kbs-raw is covered here;
  it does not need the freshness watchdog.

Suggested cadence: run `ingest-freshness.sh` monthly alongside the health
check, or from any cron that is already trusted to run hourly (the
backup-catchup wrapper pattern: cheap no-op when healthy).

## 4. Staleness has a schedule, not a panic

`scripts/staleness-sweep.sh` reports entries older than the shelf life
(default 180d), flagging those containing volatile facts (model IDs, versions,
prices, quotas, credentials). It **never modifies** — review candidates and
either confirm, annotate, or mark `**Superseded by:**` (CONVENTIONS §8).
Provenance is the constraint: the sweep marks, the owner decides.

## 5. What is deliberately NOT swept

The raw offsite archive (sessions, chat-transcripts, memory, projects-memory,
packs — e.g. a `kbs-raw`-style repo) is immutable history. No supersession
markers, no staleness sweep, no deletion. It is the raw layer the wiki summary
layer points back to — the retrieval-hook and supersession conventions apply to
the summary layer only. The name is instance-specific; only the *role* is
portable.
