#!/usr/bin/env bash
set -euo pipefail

# Unified bench runner for Bedrock.
# - Ensures build exists (optional auto-build)
# - Injects BEDROCK_GIT_REV and BEDROCK_TIMESTAMP_UTC (stable provenance)
# - Writes JSON to requested path
#
# This script DOES NOT change frozen bench_spec_v1 methodology.
# It only standardizes "how to run".

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BEDROCK_BUILD_DIR:-$ROOT/build}"

TARGET_NAME="${1:-}"
shift || true

VARIANT="${BEDROCK_BENCH_VARIANT:-scalar}"
OUT_PATH="${BEDROCK_BENCH_OUT:-}"

AUTO_BUILD="${BEDROCK_AUTO_BUILD:-1}" # 0/1

usage() {
  cat <<'EOF'
Usage:
  ./scripts/bench.sh <target_name> --out <json_path> [--variant scalar|avx2]

Env:
  BEDROCK_BUILD_DIR       (default: bedrock/build)
  BEDROCK_BENCH_VARIANT   (default: scalar)
  BEDROCK_BENCH_OUT       (optional default output path)
  BEDROCK_AUTO_BUILD      0/1 (default: 1)

Notes:
- This script runs build/bin/bedrock_bench.
- Bench binary already enforces correctness gate; failures exit non-zero.
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
    --out)
      [[ $# -ge 2 ]] || { echo "Missing value for --out" >&2; exit 2; }
      OUT_PATH="$2"; shift 2 ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${OUT_PATH:-}" ]]; then
  echo "Missing --out <json_path>" >&2
  usage
  exit 2
fi

BIN="$BUILD_DIR/bin/bedrock_bench"
if [[ ! -x "$BIN" ]]; then
  # Try to find it if layout differs
  found="$(find "$BUILD_DIR" -maxdepth 5 -type f -name bedrock_bench -perm -111 2>/dev/null | head -n 1 || true)"
  if [[ -n "$found" ]]; then
    BIN="$found"
  fi
fi

if [[ ! -x "$BIN" ]]; then
  if [[ "$AUTO_BUILD" -eq 1 ]]; then
    echo "[bedrock] bench binary not found; auto-building..." >&2
    "$ROOT/scripts/build.sh"
  fi
fi

# Re-check
BIN="$BUILD_DIR/bin/bedrock_bench"
if [[ ! -x "$BIN" ]]; then
  found="$(find "$BUILD_DIR" -maxdepth 5 -type f -name bedrock_bench -perm -111 2>/dev/null | head -n 1 || true)"
  if [[ -n "$found" ]]; then
    BIN="$found"
  fi
fi

if [[ ! -x "$BIN" ]]; then
  echo "[bedrock] ERROR: bedrock_bench not found/executable in $BUILD_DIR" >&2
  echo "[bedrock] Run: ./scripts/build.sh" >&2
  exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$OUT_PATH")"

# Provenance injection (best-effort; binary also has internal fallback for timestamp)
GIT_REV="unknown"
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_REV="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

TS_UTC="unknown"
if command -v date >/dev/null 2>&1; then
  TS_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo unknown)"
fi

export BEDROCK_GIT_REV="$GIT_REV"
export BEDROCK_TIMESTAMP_UTC="$TS_UTC"

echo "[bedrock] run bench_spec_v1"
echo "[bedrock] bin:     $BIN"
echo "[bedrock] target:  $TARGET_NAME"
echo "[bedrock] variant: $VARIANT"
echo "[bedrock] out:     $OUT_PATH"
echo "[bedrock] git_rev: $BEDROCK_GIT_REV"
echo "[bedrock] ts_utc:  $BEDROCK_TIMESTAMP_UTC"

exec "$BIN" \
  --target "$TARGET_NAME" \
  --variant "$VARIANT" \
  --out "$OUT_PATH"
