#!/usr/bin/env python3
"""
Compare a current bench_spec_v1 run JSON against a baseline JSON.

Goals:
- Stable, deterministic comparison logic
- Minimal dependencies (stdlib only)
- Report regressions in a way that's robust to small noise
- Keep "spec frozen": compare does not change how numbers are measured

Comparison:
- Match results by (kernel, variant, n)
- Use p50_ns_per_element as primary (stable median)
- Compute ratio = cur / base
- Flag if ratio > (1 + threshold)

Outputs:
- Human-readable summary to stdout
- Exit code:
    0: ok
    2: regression found
    3: schema mismatch / parse error
"""

from __future__ import annotations
import json
import sys
from dataclasses import dataclass
from typing import Dict, Tuple, Any, List

Key = Tuple[str, str, int]  # (kernel, variant, n)


@dataclass(frozen=True)
class Row:
    kernel: str
    variant: str
    n: int
    p50: float
    p95: float
    correct: bool


def die(code: int, msg: str) -> None:
    print(msg, file=sys.stderr)
    sys.exit(code)


def load(path: str) -> Any:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        die(3, f"[bedrock] ERROR: failed to load json: {path}: {e}")


def parse_rows(doc: Any) -> Dict[Key, Row]:
    if not isinstance(doc, dict):
        die(3, "[bedrock] ERROR: json root must be object")
    if doc.get("suite_id") != "bench_spec_v1":
        die(3, f"[bedrock] ERROR: suite_id mismatch: {doc.get('suite_id')!r}")

    res = doc.get("results")
    if not isinstance(res, list) or not res:
        die(3, "[bedrock] ERROR: results missing/empty")

    out: Dict[Key, Row] = {}
    for r in res:
        if not isinstance(r, dict):
            continue
        k = str(r.get("kernel", ""))
        v = str(r.get("variant", ""))
        n = int(r.get("n", -1))
        p50 = float(r.get("p50_ns_per_element", float("nan")))
        p95 = float(r.get("p95_ns_per_element", float("nan")))
        correct = bool(r.get("correct", False))
        if not k or not v or n < 0:
            continue
        out[(k, v, n)] = Row(kernel=k, variant=v, n=n, p50=p50, p95=p95, correct=correct)
    if not out:
        die(3, "[bedrock] ERROR: no parseable result rows")
    return out


def fmt_ratio(x: float) -> str:
    return f"{x:.4f}x"


def main(argv: List[str]) -> int:
    if len(argv) < 3:
        print(
            "Usage:\n"
            "  compare_baseline.py <baseline.json> <current.json> [--threshold 0.03]\n"
            "\n"
            "Notes:\n"
            "  threshold is relative regression on p50 (default 0.03 => +3%)\n",
            file=sys.stderr,
        )
        return 2

    base_path = argv[1]
    cur_path = argv[2]

    threshold = 0.03
    if "--threshold" in argv:
        i = argv.index("--threshold")
        if i + 1 >= len(argv):
            die(3, "[bedrock] ERROR: missing value after --threshold")
        threshold = float(argv[i + 1])

    base_doc = load(base_path)
    cur_doc = load(cur_path)

    base = parse_rows(base_doc)
    cur = parse_rows(cur_doc)

    # Require correctness in both
    bad_base = [k for k, r in base.items() if not r.correct]
    bad_cur = [k for k, r in cur.items() if not r.correct]
    if bad_base:
        die(3, f"[bedrock] ERROR: baseline has incorrect rows: {bad_base[:10]}")
    if bad_cur:
        die(3, f"[bedrock] ERROR: current has incorrect rows: {bad_cur[:10]}")

    # Compare intersection only; missing keys are reported but not auto-fail (stable evolution)
    keys = sorted(set(base.keys()) & set(cur.keys()))
    missing_in_cur = sorted(set(base.keys()) - set(cur.keys()))
    missing_in_base = sorted(set(cur.keys()) - set(base.keys()))

    if not keys:
        die(3, "[bedrock] ERROR: no overlapping result keys to compare")

    worst = None  # (ratio, key, base_p50, cur_p50)
    regressions = []

    for k in keys:
        b = base[k]
        c = cur[k]
        if b.p50 <= 0 or c.p50 <= 0:
            continue
        ratio = c.p50 / b.p50
        if worst is None or ratio > worst[0]:
            worst = (ratio, k, b.p50, c.p50)
        if ratio > 1.0 + threshold:
            regressions.append((ratio, k, b.p50, c.p50))

    print("[bedrock] compare baseline")
    print(f"[bedrock] baseline: {base_path}")
    print(f"[bedrock] current : {cur_path}")
    print(f"[bedrock] threshold: +{threshold*100:.2f}% (p50)")

    if missing_in_cur:
        print(f"[bedrock] NOTE: missing in current (ignored): {len(missing_in_cur)}")
    if missing_in_base:
        print(f"[bedrock] NOTE: new in current (ignored): {len(missing_in_base)}")

    if worst:
        ratio, k, bp, cp = worst
        print(
            "[bedrock] worst ratio (p50): "
            f"{k[0]} {k[1]} n={k[2]}  "
            f"base={bp:.6g}  cur={cp:.6g}  ratio={fmt_ratio(ratio)}"
        )

    if regressions:
        regressions.sort(reverse=True, key=lambda x: x[0])
        print(f"[bedrock] REGRESSION FOUND: {len(regressions)} case(s)")
        for ratio, k, bp, cp in regressions[:50]:
            print(
                f"  - {k[0]} {k[1]} n={k[2]}  "
                f"base={bp:.6g}  cur={cp:.6g}  ratio={fmt_ratio(ratio)}"
            )
        return 2

    print("[bedrock] OK: no regressions over threshold")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
