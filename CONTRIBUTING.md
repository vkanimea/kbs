# Contributing to KBS

Thank you for your interest in improving KBS. This project follows the **edit upstream, sync down** rule: changes are made in the system repo and propagated to data repos via `scripts/kbs-sync.sh`.

## Quick Start

1. Fork the repository.
2. Create a feature branch from `main`.
3. Make your changes.
4. Run the tests (see below).
5. Open a pull request.

## Running Tests

```bash
# Checker and linter tests
bash tests/test-checkers.sh

# Backup verification tests
bash tests/test-backup-verify.sh

# Version consistency check
bash scripts/check-doc-versions.sh

# Word count guard (agents.md must stay under 1,200 words)
wc -w agents.md
```

All tests must pass before a PR is merged.

## Edit Upstream, Sync Down

- **System repo** (this repo): holds scripts, docs, templates, and `agents.md`. Changes here propagate to all data repos.
- **Data repo** (each user's private instance): holds INBOX, wiki, DECISIONS, etc. Never edit system files in a data repo — they will be overwritten on sync.

If you need to change a template or script, edit it here, then users run `scripts/kbs-sync.sh --check` to detect drift and `scripts/kbs-sync.sh` to apply updates.

## Code Style

- Shell scripts: `shellcheck` clean, `set -euo pipefail`.
- Python: type hints where practical, no external dependencies beyond stdlib.
- Markdown: follow `CONVENTIONS.md` and `reference/writing-style.md`.
- No hardcoded instance-specific names (hostnames, remote names, paths) in public files — use environment variables with sensible defaults.

## PR Checklist

- [ ] Tests pass (`test-checkers.sh`, `test-backup-verify.sh`, `check-doc-versions.sh`)
- [ ] `agents.md` word count under 1,200
- [ ] No instance-specific names leaked (run `scripts/private-name-check.sh`)
- [ ] CHANGELOG entry added (if user-visible change)
- [ ] Version in VERSION bumped (if release)
