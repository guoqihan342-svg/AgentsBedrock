# PATCH_SPEC.md — PatchGate Protocol PP1 (Frozen v1)

Status: **FROZEN v1**  
Rule: Any change that modifies meaning (allow/deny rules, safety model, semantics) MUST bump major version (v2/v3). No silent mutations.

This document defines the only accepted edit interface for this repository:
a **single git-style unified diff patch** that can be validated automatically.

---

## 1) Patch type (required)

The patch MUST be a **git-style unified diff**:
- Contains one or more `diff --git a/... b/...` headers
- Uses `---` / `+++` markers
- Uses `@@ ... @@` hunks for content changes

The patch MUST be **text-only**.

---

## 2) Patch cardinality (required)

- The agent MUST output **exactly one** patch per request.
- The patch MUST be complete: include all intended edits.

---

## 3) Allowed operations (v1)

### Allowed
- Modify existing text files
- Add new text files
- Delete existing text files
- Add/delete empty files (may produce no hunks)

### Disallowed (hard fail)
- Binary patches (`GIT binary patch` / `Binary files ...`)
- Symlinks (mode `120000`)
- Submodules (mode `160000`)
- Rename/copy operations (`rename from/to`, `copy from/to`)
- Patches that touch `.git/` internals
- Absolute paths and path traversal
  - Exception: `/dev/null` is allowed ONLY in `---/+++` markers for add/delete
- Backslashes in paths
- Mode-only patches

---

## 4) Path rules (strict)

Each `diff --git` header MUST be:
- `diff --git a/<relpath> b/<relpath>`

Rules for `<relpath>`:
- MUST be relative (no leading `/`)
- MUST NOT contain `..` segments
- MUST NOT contain backslashes `\`
- MUST NOT be empty
- MUST NOT start with `.git/`

Additionally:
- The `<relpath>` on the `a/` side and `b/` side MUST match exactly.

---

## 5) Marker rules (strict, per-file)

For each `diff --git a/P b/P` section:

### Modified file
- `--- a/P`
- `+++ b/P`

### Added file
- `new file mode 100644` (or `100755` only if executable is required)
- `--- /dev/null`
- `+++ b/P`

### Deleted file
- `deleted file mode 100644` (or `100755` if executable)
- `--- a/P`
- `+++ /dev/null`

Notes:
- `/dev/null` is the only allowed absolute path in `---/+++` lines.
- All mode lines (if present) MUST be exactly `100644` or `100755`.

---

## 6) Hunk rules

- If a patch changes file contents, it MUST contain at least one `@@` hunk.
- Exception: adding or deleting an **empty file** may produce no hunks; this is allowed only for pure add/delete sections.
- Mode-only patches (changing file mode without content change) are NOT allowed.

---

## 7) Validation contract (source of truth)

A patch is valid if and only if:
1) It satisfies all rules in this spec, AND
2) It passes `./patch_gate.sh`, including:
   - safety checks
   - per-file marker validation
   - `git apply --check --whitespace=error`

---

End of PATCH_SPEC.md (Frozen v1).
