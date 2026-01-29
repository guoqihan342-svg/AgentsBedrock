#!/usr/bin/env bash
set -euo pipefail

# Collect the minimal, stable context bundle for AI iteration.
# Goal:
# - Avoid sending the entire repo each time
# - Preserve frozen specs + key source + scripts + latest outputs
# - Make it easy to reproduce, optimize, and keep contracts stable
#
# Output:
#   bedrock/artifacts/bedrock_ai_bundle.<UTC>.<git>.tar.gz

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART_DIR="$ROOT/artifacts"
OUT_DIR="$ART_DIR"
mkdir -p "$OUT_DIR"

GIT_REV="unknown"
if command -v git >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_REV="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
fi

TS_UTC="unknown"
if command -v date >/dev/null 2>&1; then
  TS_UTC="$(date -u +"%Y%m%dT%H%M%SZ" 2>/dev/null || echo unknown)"
fi

BUNDLE_NAME="bedrock_ai_bundle.${TS_UTC}.${GIT_REV}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[bedrock] collect_for_ai"
echo "[bedrock] root: $ROOT"
echo "[bedrock] git:  $GIT_REV"
echo "[bedrock] ts:   $TS_UTC"
echo "[bedrock] tmp:  $TMP_DIR"

mkdir -p "$TMP_DIR/$BUNDLE_NAME"

copy_if_exists() {
  local src="$1"
  local dst="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi
}

# --- Frozen contracts / docs (if present) ---
copy_if_exists "$ROOT/README.md" "$TMP_DIR/$BUNDLE_NAME/README.md"
copy_if_exists "$ROOT/docs" "$TMP_DIR/$BUNDLE_NAME/docs"

# --- Core code needed for performance iteration ---
copy_if_exists "$ROOT/CMakeLists.txt" "$TMP_DIR/$BUNDLE_NAME/CMakeLists.txt"
copy_if_exists "$ROOT/include" "$TMP_DIR/$BUNDLE_NAME/include"
copy_if_exists "$ROOT/src" "$TMP_DIR/$BUNDLE_NAME/src"
copy_if_exists "$ROOT/platform" "$TMP_DIR/$BUNDLE_NAME/platform"

# --- Scripts (build/bench/baseline/compare) ---
copy_if_exists "$ROOT/scripts" "$TMP_DIR/$BUNDLE_NAME/scripts"

# --- Bench inputs/outputs/baselines (small but critical) ---
copy_if_exists "$ROOT/bench/baselines" "$TMP_DIR/$BUNDLE_NAME/bench/baselines"
copy_if_exists "$ROOT/bench/out" "$TMP_DIR/$BUNDLE_NAME/bench/out"

# --- Optional: CI workflow (helps other AIs understand constraints) ---
copy_if_exists "$ROOT/../.github/workflows" "$TMP_DIR/$BUNDLE_NAME/.github/workflows"

# Create a manifest
MANIFEST="$TMP_DIR/$BUNDLE_NAME/MANIFEST.txt"
{
  echo "bundle: $BUNDLE_NAME"
  echo "git_rev: $GIT_REV"
  echo "timestamp_utc: $TS_UTC"
  echo ""
  echo "included:"
  (cd "$TMP_DIR/$BUNDLE_NAME" && find . -type f | sort)
} > "$MANIFEST"

OUT_TGZ="$OUT_DIR/$BUNDLE_NAME.tar.gz"
tar -C "$TMP_DIR" -czf "$OUT_TGZ" "$BUNDLE_NAME"

echo "[bedrock] wrote:"
echo "  $OUT_TGZ"
echo "[bedrock] next:"
echo "  send this .tar.gz to AI for iterative optimization"
