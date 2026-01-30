---
name: Bug report
about: Report a PatchGate false positive/false negative or regression
title: "[bug] "
labels: bug
---

## Summary (one sentence)
Describe the problem briefly.

## Type
- [ ] False positive (valid patch rejected)
- [ ] False negative (unsafe patch accepted)
- [ ] Regression (previously correct behavior changed)
- [ ] CI/workflow issue

## Expected vs Actual
**Expected:**  
**Actual:**  

## Reproducer patch (required)
Paste the smallest unified diff that reproduces the issue:

```diff
diff --git a/... b/...
...
```

## Gate output (required)
Paste the exact output of:
- `./patch_gate.sh <your.diff>`

```
[patch_gate] ...
```

## Environment (if relevant)
- OS:
- Shell:
- Git version:
- CI (GitHub Actions / other):

## Notes
Anything else that helps (links to PRs, logs, etc.).
```
