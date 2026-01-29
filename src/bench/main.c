#include "bedrock.h"
#include "bedrock_bench.h"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static void usage(const char* argv0) {
  fprintf(stderr,
    "Usage:\n"
    "  %s --target <target_name> --variant <variant> --out <path>\n"
    "\n"
    "Required:\n"
    "  --target   Target name (e.g. linux_x86_64_avx2)\n"
    "  --variant  Variant (default: scalar; avx2 is explicit opt-in)\n"
    "  --out      Output JSON path\n"
    "\n"
    "Notes:\n"
    "  - This runner emits bench_spec_v1 JSON (frozen methodology).\n"
    "  - Correctness gate is enforced; failure returns non-zero.\n",
    argv0 ? argv0 : "bedrock_bench"
  );
}

static const char* arg_value(int* i, int argc, char** argv, const char* name) {
  if (*i + 1 >= argc) {
    fprintf(stderr, "Missing value for %s\n", name);
    return NULL;
  }
  (*i)++;
  return argv[*i];
}

int main(int argc, char** argv) {
  const char* target = "linux_x86_64_avx2";
  const char* variant = "scalar";
  const char* out = NULL;

  // Minimal, strict flag parsing
  for (int i = 1; i < argc; i++) {
    const char* a = argv[i];
    if (strcmp(a, "-h") == 0 || strcmp(a, "--help") == 0) {
      usage(argv[0]);
      return 0;
    } else if (strcmp(a, "--target") == 0) {
      const char* v = arg_value(&i, argc, argv, "--target");
      if (!v) return 2;
      target = v;
    } else if (strcmp(a, "--variant") == 0) {
      const char* v = arg_value(&i, argc, argv, "--variant");
      if (!v) return 2;
      variant = v;
    } else if (strcmp(a, "--out") == 0) {
      const char* v = arg_value(&i, argc, argv, "--out");
      if (!v) return 2;
      out = v;
    } else {
      fprintf(stderr, "Unknown arg: %s\n", a);
      usage(argv[0]);
      return 2;
    }
  }

  if (!out || out[0] == '\0') {
    fprintf(stderr, "Missing required --out <path>\n");
    usage(argv[0]);
    return 2;
  }

  // Run spec v1
  int rc = brk_bench_spec_v1_run(target, variant, out);
