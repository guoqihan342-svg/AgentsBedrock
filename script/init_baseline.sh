#!/usr/bin/env bash
set -euo pipefail

# Generate baseline JSON for a target on a stable machine.
#
# Policy (important):
# - Baseline is the "truth source" used for long-term comparisons.
# - DO NOT generate baseline on GitHub Actions shared runners.
# - Prefer a pinned, stable host with controlled governor/thermal conditions.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGET_NAME="${1:-}"
shift || true

VARIANT="scalar"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/init_baseline.sh <target_name> [--variant scalar|avx2]

Examples:
  ./scripts/init_baseline.sh linux_x86_64_avx2 --variant scalar

Output:
  bench/baselines/<target_name>/bench_spec_v1.json

Notes:
- This script refuses to run on GitHub Actions by default.
- You can override refusal with BEDROCK_ALLOW_BASELINE_IN_CI=1 (NOT recommended).
EOF
}

if [[ -z "$TARGET_NAME" ]]; then
  echo "Missing <target_name>" >&2
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --variant)
      [[ $# -ge 2 ]] || { echo "Missing value for --variant" >&2; exit 2; }
      VARIANT="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2 ;;
  esac
done

# Refuse in CI (GitHub Actions)
if [[ "${GITHUB_ACTIONS:-}" == "true" && "${BEDROCK_ALLOW_BASELINE_IN_CI:-0}" != "1" ]]; then
  echo "[bedrock] REFUSE: baseline generation inside GitHub Actions is disabled." >&2
  echo "[bedrock] Reason: shared runner noise makes baseline untrustworthy." >&2
  echo "[bedrock] If you truly want it: set BEDROCK_ALLOW_BASELINE_IN_CI=1 (not recommended)." >&2
  exit 3
fi

BASE_DIR="$ROOT/bench/baselines/$TARGET_NAME"
OUT_JSON="$BASE_DIR/bench_spec_v1.json"
TMP_JSON="$BASE_DIR/.bench_spec_v1.tmp.json"

mkdir -p "$BASE_DIR"

echo "[bedrock] init baseline"
echo "[bedrock] target:  $TARGET_NAME"
echo "[bedrock] variant: $VARIANT"
echo "[bedrock] out:     $OUT_JSON"

# Run bench to tmp, then atomic replace
"$ROOT/scripts/bench.sh" "$TARGET_NAME" --variant "$VARIANT" --out "$TMP_JSON"

# Validate JSON strongly if python3 exists
if command -v python3 >/dev/null 2>&1; then
  python3 - <<PY
import json, sys
p = r"""$TMP_JSON"""
with open(p, "r", encoding="utf-8") as f:
    d = json.load(f)

assert d.get("suite_id") == "bench_spec_v1"
res = d.get("results", [])
assert isinstance(res, list) and len(res) > 0

bad = [r for r in res if not r.get("correct", False)]
assert not bad, "correctness failed in baseline generation"
print("[bedrock] baseline json ok, correctness ok")
PY
else
  echo "[bedrock] WARN: python3 missing; baseline validation is shallow." >&2
fi

mv -f "$TMP_JSON" "$OUT_JSON"

echo "[bedrock] baseline written:"
echo "  $OUT_JSON"
echo "[bedrock] next:"
echo "  git add $OUT_JSON && git commit -m \"baseline: bench_spec_v1 $TARGET_NAME\""
