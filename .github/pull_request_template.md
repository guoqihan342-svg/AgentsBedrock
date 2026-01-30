# PatchGate PR Template (v1)

> This repo is **Frozen Charter v1**. Any semantic protocol change requires a major bump (v2/v3).
> PatchGate is deny-by-default. Regression must remain stable.

---

## 0) What changed (short)
- [ ] Bugfix (v1-compatible)
- [ ] Gate implementation refactor (no semantic change)
- [ ] Error message improvement (no semantic change)
- [ ] CI robustness improvement (no semantic change)
- [ ] Protocol change (REQUIRES v2/v3)  ⚠️

If "Protocol change", specify:
- New major version: v2/v3
- Files updated: AGENTS / PATCH_SPEC / Charter
- Motivation and migration notes

---

## 1) Hard gates (MUST PASS or DO NOT MERGE)

### Protocol invariance (v1)
- [ ] No silent meaning changes to `AGENTS.md`, `PATCH_SPEC.md`, `FROZEN_CHARTER_v1.md`
- [ ] No new runtime dependencies beyond: bash, git, awk, grep, mktemp
- [ ] No network calls

### Regression corpus
- [ ] `./tests/run.sh` PASS locally (if applicable)
- [ ] CI Regression PASS (`tests/run.sh`)

### Security must-not-regress (False Negative = 0)
Confirm the following remain blocked (MUST FAIL):
- [ ] binary patch markers
- [ ] symlink/submodule modes (120000/160000)
- [ ] rename/copy metadata
- [ ] touching `.git/`
- [ ] path traversal (`../`), absolute paths (except `/dev/null` markers), backslashes
- [ ] marker/header mismatch
- [ ] illegal modes (not 100644/100755)
- [ ] mode-only patches

### Usability must-not-regress
Confirm the following remain allowed (MUST PASS when valid):
- [ ] normal modify patches with hunks
- [ ] add text files (`/dev/null` + correct markers)
- [ ] delete files (`/dev/null` + correct markers)
- [ ] add/delete empty files (if supported by current gate behavior)

---

## 2) Value check (merge only if value is real)

Score each 0–5 (optional, but recommended):
- False positives reduced (legitimate patches previously blocked now pass): __/5
- Error messages more actionable/specific: __/5
- Runtime stable or improved (CI remains fast): __/5
- Implementation simpler/clearer: __/5
- Doc ↔ gate behavior consistency improved: __/5

Brief evidence (links/log snippets):
- Evidence:

---

## 3) How this was validated (paste commands or CI link)
- [ ] CI link:
- [ ] Local commands (optional):
  - `chmod +x patch_gate.sh tests/run.sh`
  - `./tests/run.sh`

---

## 4) Notes for reviewers (keep short)
- Risk:
- Rollback plan:
