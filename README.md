# PatchGate — AI-Safe Repo Changes (Diff Protocol + CI Gate)

PatchGate is a tiny, agent-first foundation that makes AI/LLM repo changes **auditable, verifiable, and safe**.

It enforces a single interface:

> **One git-style unified diff patch** → **validated by PatchGate** → **enforced by CI**

This repository is intentionally minimal and Linux-first, designed to be copied into other repos as a base layer for AI-assisted development.

Status: **Frozen Charter v1**

---

## Why PatchGate exists

Common failure modes in AI/agent code edits:
- Outputting full files (hard to review, easy to drift)
- Guessing context (patch doesn’t apply)
- Unsafe operations (path traversal, touching `.git/`, symlinks/submodules, binary diffs)
- Large, noisy edits (format churn, broad refactors)
- Hidden structural moves (rename/copy) that reduce auditability

PatchGate turns AI output into a **strictly validated patch artifact** and blocks everything else.

---

## Repository contents (v1)

Core (frozen semantics):
- `AGENTS.md` — agent constitution (strict diff-only output contract)
- `PATCH_SPEC.md` — patch protocol specification (PP1 / Frozen v1)
- `patch_gate.sh` — gate implementation (enforces PP1 + safety + clean apply)

Regression (frozen expected outcomes):
- `tests/patch_samples.md` — must-pass / must-fail patch samples
- `tests/run.sh` — regression runner (portable, minimal deps)

CI enforcement:
- `.github/workflows/patchgate.yml` — runs:
  1) regression (`./tests/run.sh`)
  2) PR diff validation (base→head diff validated by PatchGate)

Governance / docs:
- `FROZEN_CHARTER_v1.md` — frozen governance + merge criteria
- `CONTRIBUTING.md` — contribution rules (v1-compatible only)
- `SECURITY.md` — security stance and threat model
- `CHANGELOG.md` — versioned change log
- `LICENSE` — MIT

---

## Quick start

### Local validation
Make scripts executable:
```bash
chmod +x patch_gate.sh
chmod +x tests/run.sh
```

Run regression (must stay stable in v1):
```bash
./tests/run.sh
```

Validate any patch:
```bash
./patch_gate.sh < change.diff
# or
./patch_gate.sh change.diff
```

### GitHub Actions (recommended)
PRs automatically run PatchGate via:
- `.github/workflows/patchgate.yml`

Recommended GitHub settings:
- Enable **Branch protection** for `main`
- Require workflow **PatchGate** to pass before merge
- Disallow direct pushes to `main` (PR-only)

---

## Agent output contract (Frozen v1)

Agents MUST comply with `AGENTS.md` and `PATCH_SPEC.md`.

Strict output format:
- Output exactly **one** fenced code block with language tag `diff`
- Must contain a git-style unified diff starting with `diff --git a/... b/...`

Outside the diff block:
- Allowed: nothing OR one optional line `PATCH READY`
- Disallowed: any other prose, explanations, summaries, file dumps, multiple code blocks, multi-patch outputs

If insufficient info:
- Output NO patch
- Output exactly one line:
  - `NEED INFO: <one question>`

---

## What PatchGate blocks by default (deny-by-default)

Hard-fail categories:
- Binary patches (`GIT binary patch` / `Binary files ...`)
- Symlinks/submodules (modes `120000` / `160000`)
- Rename/copy metadata (`rename from/to`, `copy from/to`)
- Touching `.git/` internals
- Path traversal (`../`), absolute paths (except `/dev/null` markers), backslashes
- Marker/header mismatch (diff header path differs from `---/+++` targets)
- Illegal modes (anything not exactly `100644` or `100755`)
- Mode-only patches (policy: not allowed)

Validation also requires:
- `git apply --check --whitespace=error` clean-apply

---

## How to judge whether an optimization is successful (acceptance metrics)

You may consult multiple AIs and then decide whether to submit changes.
Use these objective criteria.

### Hard gates (any fail => DO NOT MERGE)
1) Protocol meaning unchanged in v1 (or major bump explicitly declared)
2) Regression must pass:
   - `./tests/run.sh` PASS (locally and in CI)
3) No security regressions (false negative = 0):
   - must-fail classes remain blocked (binary/symlink/submodule/rename/copy/path/.git/mismatch/illegal mode)
4) No usability regressions:
   - must-pass classes still pass (normal modify/add/delete; empty file add/delete if supported by gate)

### Value scoring (merge only if value is real)
Prefer changes that achieve one or more:
- Reduce false positives (valid patches previously blocked now pass) without any false negatives
- Improve error messages (more actionable `[patch_gate] FAIL:` reasons)
- Keep CI fast (no noticeable runtime regressions)
- Improve clarity / reduce complexity while preserving behavior
- Improve doc ↔ gate consistency

---

## Environment prerequisites (Linux-first)

Minimum requirements:
- `bash`
- `git`
- `awk`
- `grep`
- `mktemp`

No network access required. No external dependencies required.

GitHub Actions `ubuntu-latest` is sufficient.

---

## Versioning / freezing policy

- Semantics are frozen by major version.
- Any allow/deny or contract change requires a major bump (v2/v3).
- v1 changes are limited to bugfixes and clarity improvements that preserve v1 meaning.

PatchGate is a base layer: safe change protocol + CI enforcement.
