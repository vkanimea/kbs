# Atoms — exact fixes, captured whole

## Why Atoms Exist

The most reusable knowledge in this system is the smallest: one exact error, its
exact fix, the working command, and why it works. Most systems capture this
badly — the error is paraphrased, the fix is described in prose, the command is
omitted — and the atom becomes useless the moment someone needs to apply it.
An atom captured WHOLE is copy-pasteable by a future agent with zero rediscovery.

An atom answers the question: "what is the exact sequence that turns this error
into this fixed state?"

## The Four Parts

| Part | Rule |
|---|---|
| **Exact error:** | The literal error string, copy-pasted. Not a paraphrase. Quoted exactly so it can be grepped and matched later. |
| **Exact fix:** | The change that fixed it, stated concretely ("added an exit-status check", not "improved error handling"). |
| **Command:** | The exact command(s) that work — past tense proven, not intended. Include flags. |
| **Why:** | The mechanism. Why the error occurred and why the fix resolves it. This is what makes the atom transferable to a *similar* problem. |

## Where Atoms Live

Atoms are not a separate file type. They are four optional fields inside a
normal entry — most often a FAILURES.md or SUCCESSES.md entry, since those
already record what broke and what fixed it:

- `**Exact error:**` — the literal error text.
- `**Exact fix:**` — the concrete change.
- `**Command:**` — the working command(s).
- `**Why:**` — the mechanism.

The linter (`scripts/kbs-lint.sh`) enforces the same rule it applies to every
optional field: present-but-empty is an ERROR, absent is fine. Legacy entries
without atom fields remain valid — atoms are added when the knowledge exists,
never fabricated to fill a template.

A quick capture that is only an atom (no full failure narrative) goes to
INBOX.md with the four fields inline; the ingest step files it into the right
entry.

## Worked Exemplar — copy this shape

```markdown
## 2026-10-19 | faster-whisper install on a host without python3-venv
**What failed:** python3 -m venv failed with "ensurepip is not available", and a plain pip install was refused (PEP 668 externally-managed-environment).
**Exact error:** The virtual environment was not created successfully because ensurepip is not available.
**Exact fix:** Install into an isolated target dir instead of system site-packages, then run with PYTHONPATH pointing at it.
**Command:** python3 -m pip install --target /tmp/fwlibs --break-system-packages faster-whisper
**Why:** --target installs to an arbitrary directory without touching system site-packages, so PEP 668 does not apply; PYTHONPATH=/tmp/fwlibs makes the interpreter find the packages. The venv module itself is a separate Debian package (python3.11-venv) that is not installed.
**Resolved:** Yes
**Query:** how to install pip packages without venv or breaking system python
```

Note the entry is still a normal FAILURES entry — required fields first, atom
fields layered on top. The `**Query:**` line (see the retrieval-hook
convention in CONVENTIONS §8) makes the atom findable by keyword search.

---

## Report Format

Atoms do not need their own processing report. When atoms are captured in
bulk (e.g. after a session that hit many exact errors), count them in the
session close-out note: "atoms captured: [n]".
