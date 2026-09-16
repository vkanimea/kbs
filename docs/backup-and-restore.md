# Backup & Restore — Git-Remote Pattern

KBS treats **markdown + git as the system of record**: every index (RAG, topic,
snapshots) is regenerable and git-ignored. That makes a git remote the natural
backup backend — this pattern replaces ad-hoc tarball copies with a versioned,
off-site, restorable history.

**Architecture:** the *system* repo (this one) can stay public; the *data* repo
(your installed KBS, `~/kbs`) must be **private** — it contains your knowledge,
decisions, actions, and any ingested documents.

---

## Setup (once)

```bash
cd ~/kbs
git init && git add -A && git commit -m "KBS data initial"   # .gitignore pre-configured
git remote add origin https://github.com/<you>/<kbs-data>.git # PRIVATE repo
cp .env.template .env                                        # add GITHUB_TOKEN (write)
git config credential.helper '!bash scripts/git-credential-env.sh'
git push -u origin master
```

Nightly automation:

```cron
45 23 * * * ~/kbs/scripts/nightly-backup.sh >/dev/null 2>&1
```

`nightly-backup.sh` commits and pushes only when something changed, re-asserts the
repo-local credential helper (so fresh clones stay push-capable), and logs to
`backup.log` (git-ignored).

## What a clone restores — and what you rebuild

| Restored from the data repo | Rebuilt after clone |
|---|---|
| All KBs: topics, raw, raw-assets (PDFs, images) | `.env` — secrets never enter git, by design |
| Capture/learning files: INBOX, ACTIONS, DECISIONS, FAILURES, SUCCESSES, JOURNAL, log.md | RAG indexes — `KB_NAME=<kb> scripts/rag-index.sh` (needs Ollama + embedding model) |
| System snapshot: agents.md, SYSTEM.md, scripts/, reference/, examples/ | Cron entries (host state, not git) |

## Restore procedure

```bash
git clone https://github.com/<you>/<kbs-data>.git ~/kbs && cd ~/kbs
cp .env.template .env                      # add GITHUB_TOKEN; chmod 600
ollama pull nomic-embed-text               # or your configured embedding model
for kb in <your-kb-names>; do KB_NAME=$kb scripts/rag-index.sh; done
# re-add cron entries (hourly-ingest.sh, nightly-backup.sh)
KB_NAME=<kb> scripts/rag-query.sh "test"   # verify retrieval
git ls-remote origin                       # verify push/pull auth
```

## Operational notes

- **Freshness = last push.** Nightly keeps staleness <24h; run
  `scripts/nightly-backup.sh` manually after a big session.
- The data repo snapshots the *system files* as-of-last-commit. Correct for
  restoring operations; for system *development* use the public system repo,
  which may be newer.
- Keep a `RESTORE.md` in your data-repo root with your instance specifics
  (repo URL, KB names, cron lines, model name) — it travels with the backup,
  which is exactly where you need it during a restore.
- If a data repo is ever made public, treat all content as exposed and rotate
  anything sensitive.
