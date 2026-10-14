# Security

See [docs/security.md](docs/security.md) for the full security documentation covering trust boundaries, Activity Level access, token scoping, data locality, and webhook hardening.

## Summary

- **Untrusted input** (raw documents, chat transcripts) is ingested into an LLM that may have shell/git access. Run at the lowest Activity Level that suffices.
- **Chat clients cap at Level 1.** An agent harness is required for scripts, git, and backups.
- **Cloud LLMs see your content.** Only local models (Ollama, llama.cpp) keep content on-device.
- **Scope tokens** to a fine-grained, repo-limited PAT.

## Reporting

Report security issues by opening a confidential issue on the repository. Do not file public issues for vulnerabilities.
