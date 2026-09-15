# KBS SWOT Analysis — V0.114

Compared against: Obsidian/Logseq, Notion AI, the Reddit "Second Brain" pattern, and vector-RAG systems.

---

## Strengths

**S1 — Model-agnostic.** Plain-text instructions any LLM follows. Switching providers requires no migration. (Obsidian is model-agnostic for viewing only; Notion AI is provider-locked; the Reddit pattern assumed Claude Code.)

**S2 — Activity Levels.** The only system reviewed with a graduated trust-to-autonomy path (0→3) with explicit upgrade criteria and automatic downgrade on failure. Others offer manual or automated, nothing between.

**S3 — Typed relationships.** Causal reasoning via Causes / Leads To / Depends On — the system can answer "what causes X?", not just show that X links to Y. Obsidian shows links; RAG retrieves by similarity; neither reasons causally.

**S4 — Failure learning.** Structured failure capture with confidence downgrades, pattern detection, and resolution tracking. No equivalent in any compared system.

**S5 — Session close.** One command that compounds every session into wiki pages, decisions, failures, career entries, and open questions. The Reddit pattern pioneered this; KBS formalises and extends it.

**S6 — INBOX quality gate.** Entries rated at ingestion; poor entries rejected with a rewrite suggestion. Prevents garbage from entering the graph. Unique among compared systems.

**S7 — Lazy-loaded instructions (introduced V11, current V0.114).** An ~800-word core file plus on-demand reference modules keeps the LLM's per-session instruction load small, which measurably improves rule adherence in long instruction sets. The CI enforces the core file stays under 1,200 words.

**S8 — Plain text, audited, recoverable.** Markdown + git + append-only log + snapshots. Survives any technology change; every action traceable.

---

## Weaknesses

**W1 — Discipline-dependent.** At Level 0 the pipeline stalls without daily closes and weekly ingestion. Mitigation: calendar reminders, `auto-close.sh` with streak tracking, `due-actions.sh` notifications, and a deliberately minimal non-negotiable (one close command) — but no mitigation removes the dependency entirely.

**W2 — The owner is the failure sensor (partially mitigated).** The system now detects recurring problem patterns: if a HIGH-confidence solution's problem reappears in INBOX within 30 days, it flags implicitly. However, initial failure capture is still human.

**W3 — Setup friction.** Folder permissions, terminal commands, and prompt rituals demand more technical comfort than opening Notion. The one-command installer reduces but doesn't eliminate this.

**W4 — No mobile capture app.** Phone capture means a markdown editor plus git sync, or voice-to-text and paste. The `voice` style and `chat-api-adapter.py` webhook improve this, but a native app would be better.

**W5 — No live graph view.** Graphs are generated on demand (text or Mermaid). Workaround: open `wiki/topics/` as a read-only Obsidian vault for an always-on visual graph. The starter KB (`examples/starter-kb/`) gives users an immediate visual reference.

---

## Opportunities

| # | Opportunity | Effort | Value |
|---|------------|--------|-------|
| O1 | Obsidian-as-viewer guide (open wiki/topics as vault, never edit there) | Trivial | High |
| O2 | Browser extension: one-click chat/article capture | ~2 days | High — biggest daily-friction win |
| O3 | VS Code extension: capture + close from the command palette | ~3 days | Medium |
| O4 | Voice pipeline: Whisper → INBOX entry | ~1 day | Medium |
| O5 | ~~RAG retrieval layer~~ — shipped: `scripts/rag.py` (Ollama embeddings, stdlib) + `rag-index/query.sh`, rebuilt after hourly-ingest | Done | High for 100+ topic KBs |
| O6 | Community template library (starter KBs per domain) | Low | Medium — starter KB shipped |
| O7 | Enterprise: SharePoint/Copilot sync | High | Niche |
| O8 | Mobile app or PWA for capture | High | High — biggest remaining gap |

---

## Threats

**T1 — Context window limits.** 200+ topics may exceed what an LLM can survey during health check. Mitigated by INDEX.md navigation and hierarchical prioritisation; O5 is the long-term answer.

**T2 — API costs at heavy use.** Mitigation: local models (Ollama) for routine ingestion; cloud models for synthesis only.

**T3 — Abandonment.** The universal knowledge-system killer. The minimal-ritual design (one non-negotiable command) is the defence, but no architecture survives zero use.

**T4 — Quality decay without pruning.** Orphans and stale claims accumulate. Mitigated by monthly health check and (Level 2+) auto-archive policies.

**T5 — Competitor convergence.** Notion AI, Copilot, and Obsidian AI plugins improve fast. KBS's moats — activity levels, failure learning, typed reasoning — are architectural choices competitors would have to deliberately adopt, but nothing prevents that.

---

## Capability Matrix

| Capability | Obsidian | Notion AI | Reddit Pattern | RAG | KBS V0.114 |
|------------|---------|-----------|----------------|-----|---------|
| Activity levels | — | — | — | — | ✅ |
| Failure learning | — | — | — | — | ✅ (+ implicit detection) |
| Typed causal links | — | — | — | — | ✅ |
| Session close | — | — | ✅ | — | ✅ (+ streak tracking) |
| Career portfolio | — | — | ✅ | — | ✅ (+ output templates) |
| INBOX quality gate | — | — | — | — | ✅ |
| Lean lazy-loaded instructions | n/a | n/a | — | n/a | ✅ |
| Model-agnostic | viewing only | — | partial | ✅ | ✅ |
| Live visual graph | ✅ | — | — | — | on demand |
| Mobile app | ✅ | ✅ | — | — | — |
| Plain text + git | ✅ | — | ✅ | — | ✅ |
| Audit trail | — | partial | — | — | ✅ |
| Starter KB / onboarding | — | ✅ | — | — | ✅ |
| Local search index | — | — | — | ✅ | ✅ (topic-index.sh) |
| Journal grounded in wiki | — | — | — | — | ✅ |
| Hourly auto-ingest | — | — | — | — | ✅ |

---

## Assessment

KBS V0.114 is **production-ready architecture with reflective practice and automation**. The design problems identified in V10.3 — instruction bloat, duplication drift, fictional example data, dishonest installer fallbacks, decorative CI — are resolved. The starter KB, auto-close streaks, due-action reminders, topic index, frontmatter override, journal operations, and hourly ingestion address the most critical onboarding, adherence, and engagement gaps.

The remaining weaknesses are primarily ecosystem: mobile capture (W4) and browser extension (O2) are the highest-leverage next investments. The architecture itself — activity levels, failure learning, typed reasoning, lazy-loaded instructions, journal grounded in wiki — is stable and validated.

No numeric self-rating is offered — that judgement belongs to users after sustained use, and to the FAILURES.md file this system ships with.
