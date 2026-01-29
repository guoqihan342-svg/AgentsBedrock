#!/usr/bin/env bash
set -euo pipefail

# Bedrock build (Linux-first, minimal deps)
# Default: Release, no -march=native, no LTO (for stability + comparability)
# Opt-in knobs exist for extreme local benchmarking.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BEDROCK_BUILD_DIR:-$ROOT/build}"
BUILD_TYPE="${BEDROCK_BUILD_TYPE:-Release}"

# Opt-in perf knobs (default OFF)
ENABLE_LTO="${BEDROCK_ENABLE_LTO:-0}"       # 0/1
ENABLE_NATIVE="${BEDROCK_ENABLE_NATIVE:-0}" # 0/1

# Quality knob
WERROR="${BEDROCK_WERROR:-1}"               # 0/1

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build.sh [--debug|--release] [--lto] [--native] [--no-werror] [--clean]

Env:
  BEDROCK_BUILD_DIR       (default: bedrock/build)
  BEDROCK_BUILD_TYPE      (default: Release)
  BEDROCK_ENABLE_LTO      0/1 (default: 0)
  BEDROCK_ENABLE_NATIVE   0/1 (default: 0)
  BEDROCK_WERROR          0/1 (default: 1)

Notes:
- Default build is stable & comparable (no native, no LTO).
- For absolute local peak:
    ./scripts/build.sh --release --lto --native
EOF
}

CLEAN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --clean) CLEAN=1; shift ;;
    --debug) BUILD_TYPE="Debug"; shift ;;
    --release) BUILD_TYPE="Release"; shift ;;
    --lto) ENABLE_LTO=1; shift ;;
    --native) ENABLE_NATIVE=1; shift ;;
    --no-werror) WERROR=0; shift ;;
    *)
      echo "Unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v cmake >/dev/null 2>&1; then
  echo "[bedrock] cmake not found. Please install cmake >= 3.16" >&2
  exit 1
fi

if [[ "$CLEAN" -eq 1 ]]; then
  rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

# Prefer Ninja if present (faster), but do not require it.
GEN_ARGS=()
if command -v ninja >/dev/null 2>&1; then
  GEN_ARGS+=(-G Ninja)
fi

echo "[bedrock] build"
echo "[bedrock] root:       $ROOT"
echo "[bedrock] build_dir:  $BUILD_DIR"
echo "[bedrock] type:       $BUILD_TYPE"
echo "[bedrock] lto:        $ENABLE_LTO"
echo "[bedrock] native:     $ENABLE_NATIVE"
echo "[bedrock] werror:     $WERROR"

cmake -S "$ROOT" -B "$BUILD_DIR" \
  "${GEN_ARGS[@]}" \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DBEDROCK_ENABLE_LTO="$ENABLE_LTO" \
  -DBEDROCK_ENABLE_NATIVE="$ENABLE_NATIVE" \
  -DBEDROCK_WERROR="$WERROR"

cmake --build "$BUILD_DIR" -j

BIN="$BUILD_DIR/bin/bedrock_bench"
if [[ -x "$BIN" ]]; then
  echo "[bedrock] ok: $BIN"
else
  echo "[bedrock] WARN: expected binary not found: $BIN" >&2
fi
