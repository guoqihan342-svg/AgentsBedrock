# Bedrock

Bedrock 是一个 **Linux-first** 的、**极致性能导向** 的最小系统基座：  
用 **冻结的基准规范（bench_spec_v1）** + **确定性输入** + **硬性正确性门禁** 来产生可比较、可回归、可自动化的性能结果（JSON），并尽量避免依赖、避免随时代变化而返工。

> 设计目标：让 AI / 系统“第一时间”能用它做性能对比、微基准验证、回归检测。  
> 不是为人类手写维护而设计；可读性/生态不是第一优先级；**性能与稳定性是第一要务**。

---

## 核心原则（不会轻易改变）

- **规范冻结**：`bench_spec_v1` 的输入生成、测量方式、统计方式、输出 schema 都是“合同”。  
  新东西通过 **新增 spec（v2/v3）**，而不是改动 v1。
- **正确性优先于速度**：任何优化必须先过 correctness gate（reference scalar 为真相源）。
- **最少依赖**：无第三方库依赖；只依赖 C 编译器 + CMake + Linux 基础系统调用。
- **可重复/可解释**：输出 JSON 里记录环境信息（cpu/governor/pinning/timer_source 等）用于解释噪声。
- **Linux 先行、跨平台后置**：后续扩展到其他 OS 用“平台适配层”完成，不动冻结规范本身。

---

## 目录结构（最小必要）

- `include/`：稳定 API（`bedrock.h` 等）
- `src/common/`：无依赖公共组件（aligned alloc / PRNG / JSON writer / text）
- `platform/linux/`：Linux 平台实现（计时器、绑核、环境采集）
- `src/bench/`：基准实现（bench_spec_v1 + kernels）
- `bench/`
  - `out/`：bench 运行输出（JSON）
  - `baselines/<target>/bench_spec_v1.json`：基准真相源（baseline）
- `scripts/`
  - `init_baseline.sh`：生成 baseline（默认拒绝在 GitHub Actions 上生成）
  - `collect_for_ai.sh`：打包最小“给 AI 迭代用”的上下文包

---

## 依赖（尽量少）

必需：
- Linux
- `gcc` 或 `clang`
- `cmake >= 3.16`

强烈建议（用于校验/自动化）：
- `python3`（baseline JSON 校验、CI smoke）

---

## 构建（Release）

在 `bedrock/` 目录执行：

```bash
mkdir -p build
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```

产物：
- `build/bin/bedrock_bench`

> 性能极限模式（不默认启用，避免“不可比较/不可迁移”）  
> - `-DBEDROCK_ENABLE_LTO=ON`  
> - `-DBEDROCK_ENABLE_NATIVE=ON`（会绑定本机指令集，不适合跨机器 baseline）

---

## 运行基准（bench_spec_v1）

```bash
mkdir -p bench/out
BEDROCK_GIT_REV="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
./build/bin/bedrock_bench \
  --target linux_x86_64_avx2 \
  --variant scalar \
  --out bench/out/run.json
```

- `--variant scalar` 是默认真相路径（稳定、可比较）
- `--variant avx2` 是显式 opt-in（用于加速比较）

输出 JSON（冻结 schema）包含：
- `suite_id = bench_spec_v1`
- `env`（uname/cpu_model/governor/pinning_ok/pinned_cpu/timer_source/alignment_bytes…）
- `results[]`（p50/p95 ns/elem + correctness + error_abs/error_rel）

---

## 生成 baseline（性能真相源）

**baseline 必须来自稳定环境**（推荐自托管、固定机器）。  
默认策略：**脚本拒绝在 GitHub Actions 环境直接生成 baseline**（因为共享 runner 噪声大且不可控）。

在稳定机器上执行：

```bash
./scripts/init_baseline.sh linux_x86_64_avx2 --variant scalar
```

生成：
- `bench/baselines/linux_x86_64_avx2/bench_spec_v1.json`

然后提交：
```bash
git add bench/baselines/linux_x86_64_avx2/bench_spec_v1.json
git commit -m "baseline: bench_spec_v1 linux_x86_64_avx2"
```

---

## 性能稳定建议（强烈建议）

为了让数字更“硬”：

- 绑核：Bedrock 会 best-effort pin 到某个 CPU（默认策略偏向 cpu0）。  
  你也可以在外部用 `taskset`/cgroup 做更严格隔离。
- governor：建议 `performance`
- 尽量减少后台进程、关闭 turbo/节能策略（如果你追求最强可比性）

---

## AI 迭代工作流（手机也能做）

你可以用 `collect_for_ai.sh` 把“AI 真正需要的最小上下文”打包：

```bash
./scripts/collect_for_ai.sh
```

会输出：
- `artifacts/bedrock_ai_bundle.<timestamp>.<git>.tar.gz`

把这个包发给 AI，它就能：
- 看到冻结规范
- 看到源码与脚本
- 看到最新 bench 输出与 baseline（如果存在）
- 做增量优化并保持一致性

---

## 版本与兼容性

- `bench_spec_v1` 是冻结合同；不会通过“偷偷修改 v1”来追求短期性能。
- 新的测量方法/新 kernel/新平台支持：走新增 spec 或新增模块，不破坏旧 spec。

---

## License

（按你的需要后续补齐：MIT / Apache-2.0 / Unlicense 等）
