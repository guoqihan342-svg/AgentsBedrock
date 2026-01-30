# Changelog

This project is governed by **Frozen Charter v1**.
Protocol semantics are frozen by major version.

Rule:
- v1 MUST NOT silently change meaning.
- Any policy/semantic change requires a major bump (v2, v3...).

---

## [Unreleased]
- (reserved)

---

## [v1] — Frozen Charter v1
### Added
Core:
- `AGENTS.md` — agent constitution (diff-only output contract)
- `PATCH_SPEC.md` — patch protocol specification (PP1 / Frozen v1)
- `patch_gate.sh` — gate implementation enforcing PP1 and safety rules

Regression:
- `tests/patch_samples.md` — frozen regression corpus (must-pass / must-fail)
- `tests/run.sh` — regression runner (portable, minimal deps)

CI:
- `.github/workflows/patchgate.yml` — CI enforcement (regression + PR patch validation)

Docs/Legal/Process:
- `README.md` — overview, usage, acceptance metrics
- `FROZEN_CHARTER_v1.md` — frozen governance and merge criteria
- `CONTRIBUTING.md` — contribution rules (v1-compatible changes only)
- `SECURITY.md` — security policy and threat model
- `LICENSE` — MIT

GitHub templates:
- `.github/pull_request_template.md` — PR checklist aligned with v1 metrics
- `.github/ISSUE_TEMPLATE/bug_report.md` — issue template for regressions/FP/FN

### Notes
- v1 is deny-by-default.
- Regression outcomes in `tests/patch_samples.md` define expected behavior.
- If any rule changes, bump to v2 and document migration.
