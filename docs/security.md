# KBS Security

## Trust Boundaries

KBS ingests **untrusted content** — documents, YouTube transcripts, chat transcripts, and anything placed in `kb/*/raw/`. This content enters an LLM that may have shell access, git access, and a `GITHUB_TOKEN`. This is a **prompt-injection risk** that grows with:

- **Activity Level 2–3** — the agent can execute scripts and git commands.
- **Goal loop** — autonomous operation amplifies the blast radius of a malicious prompt.
- **Webhook server** — `chat-api-adapter.py` accepts POSTs (now auth-gated, see below).

Mitigations:
- Run at the lowest Activity Level that suffices for your workflow.
- Scope tokens tightly (see below).
- Audit `kb/*/raw/` before bulk ingestion.
- Never pipe untrusted web content directly into an agent session.

## What Each Activity Level Can Touch

| Level | Files | Scripts | Network | Risk |
|-------|-------|---------|---------|------|
| 0 | Read only | None | None | Lowest — passive observer |
| 1 | Read + append to INBOX, wiki | None | None | Low — can propose, not execute |
| 2 | Read + write wiki, log | Read-only | None | Medium — can run scripts but not modify them |
| 3 | Full write | Read + write | Outbound (git push) | Highest — full agent harness |
| Goal loop | Full write + autonomous iteration | Full | Outbound | Highest — unsupervised |

A chat client (Claude.ai, ChatGPT web) caps at **Level 1** — it can read and propose but cannot run scripts, push git, or make network calls. An agent harness (Claude Code, pi, Aider) is required for Levels 2–3.

## Token Scoping

- Use a **fine-grained, repo-limited PAT** for the data repo — never a personal access token with org-wide scope.
- `scripts/git-credential-env.sh` serves the token from `.env` (git-ignored). The token never appears in `.git/config`.
- For the offsite remote, use a separate credential with push-only access to the backup target.

## Where Your Content Goes

| Setup | Content leaves the machine? | Notes |
|-------|---------------------------|-------|
| Ollama / llama.cpp (local) | No | Content stays on-device. Recommended for sensitive data. |
| Cloud LLM (OpenAI, Anthropic, etc.) | Yes | Your notes are sent as prompt text. Check the provider's data-use policy. |
| OpenRouter | Yes | Routed to a cloud provider. Same considerations as direct cloud use. |
| Webhook → local LLM | No | If the adapter writes to CHAT_INBOX and a local model processes it. |
| Webhook → cloud LLM | Yes | The adapter itself is local, but the downstream LLM sees the content. |

**Data sovereignty claim clarified:** KBS does not phone home and each person governs their own data repo. However, when a cloud LLM processes your content, that content leaves your machine. Only fully-local setups (Ollama, llama.cpp) keep content on-device end-to-end.

## Webhook Security

The chat API adapter (`scripts/chat-api-adapter.py`) binds to **localhost only**. As of the current version it requires:

- **`KBS_WEBHOOK_TOKEN`** — a shared secret sent via the `X-KBS-Token` header. If not set, the adapter warns on startup and accepts unauthenticated POSTs (for development only).
- **Body size limit** — 64 KiB default (`KBS_WEBHOOK_MAX_BODY`).
- **JSON only** — non-JSON content types are rejected with 415.
- **No silent fallback** — invalid JSON returns 400 instead of being treated as plain text.

For production, always set `KBS_WEBHOOK_TOKEN` and `KBS_WEBHOOK_REQUIRE_TOKEN=1`.

## Installer Safety

The install scripts (`install.sh`, `install.ps1`) download from the repository's default branch. For production use:

1. **Download, inspect, then run** — review the script before executing it.
2. **Pin to a release tag** — set `KBS_REF` to a specific tag (e.g., `v0.125`) instead of `main`.
3. **Verify checksums** — each release ships a `SHA256SUMS` file. Verify after download:
   ```bash
   sha256sum -c SHA256SUMS --ignore-missing
   ```

The Windows installer requests Administrator only for creating the symlink to the user's KBS path. If you create the directory manually, elevated privileges are not needed.

## Reporting

Report security issues by opening a confidential issue on the repository, or contact the maintainer directly. Do not file public issues for vulnerabilities.
