# Arous 服务器工具链核验

权威执行环境：Arous SSH 别名对应主机 `SARS-AORUS`，项目目录 `/home/ningbin/workspace/SV_project`。

目录与运行方式参考 `/home/ningbin/workspace/VISL_project`：RTL、testbench、testcase 分目录，根目录使用 Makefile 和 filelist，生成物进入 `csrc/`、`out/`、`log/`。本项目不会复制 VISL 的设计代码，并将其波形型 TB 要求提升为 self-checking TB。

核验日期：2026-08-31（Asia/Shanghai）。以下结论来自服务器实际命令，不沿用本地 Windows 工具链结果。

## 已实测发现

| 工具 | Arous 路径/版本 | 状态 |
|---|---|---|
| OS | Linux 6.8.0-1060-gke x86_64 | 可用 |
| Make | `/usr/bin/make`，GNU Make 4.3 | 可用；本项目主运行入口 |
| Git | `/usr/bin/git`，2.43.0 | 可用 |
| Python | `/usr/bin/python3`，3.12.3 | 可用 |
| Icarus | `/usr/local/bin/iverilog`，12.0-devel (`fd69d4e`) | SystemVerilog 探针编译 PASS |
| VVP | Icarus 配套运行时 | 探针运行并输出 `PASS arous_systemverilog_probe` |
| Verible | `/usr/local/bin/verible-verilog-lint` | 拆分探针 lint PASS |
| VCS/Verdi/DVE | 登录 shell 默认 PATH 未找到 | VISL_project 的 Makefile 依赖 VCS，但当前会话不能直接调用；本项目 Makefile 自动回退 Icarus |
| GTKWave | `/usr/bin/gtkwave` | 可用；需要图形会话/转发时另行确认 |
| Vivado | 默认 PATH 未找到 | 当前不可直接调用；不宣称不存在于服务器其他位置 |
| Verilator | 默认 PATH 未找到 | 当前不可直接调用；不宣称未安装 |

## Arous 主入口

- `make PROBLEM=<题号> TOPMODULE=<TB顶层>`：按 VISL 风格完成准备、编译和运行；当前自动选择可用模拟器。
- `make lint PROBLEM=<题号>`：根据 `filelists/<题号>.f` 运行 Verible。
- `make regress`：后续在存在用户 RTL/TB 后遍历 15 题。
- `scripts/*.sh`：保留为底层/兼容入口，但 Makefile 是日常主入口。
- 所有生成物写入项目内 `work/`，不会扫描或修改服务器上的其他工程。

Windows `.ps1` 脚本仅保留作本地辅助，不是验收权威入口。最终 PASS 证据必须来自 Arous 的实际命令和日志。

## 实际探针证据

在项目的忽略目录 `work/tool_probe/` 中使用最小 `logic`、`always_comb` 和 self-checking TB：

```bash
verible-verilog-lint work/tool_probe/tool_probe.sv work/tool_probe/tb.sv
iverilog -g2012 -Wall -s tb -o work/tool_probe/probe_split.vvp \
  work/tool_probe/tool_probe.sv work/tool_probe/tb.sv
vvp work/tool_probe/probe_split.vvp
```

Verible 返回 0；Icarus 编译返回 0；VVP 输出 `PASS arous_systemverilog_probe`。空项目运行 `scripts/regress.sh` 得到 `ran=0 failed=0 total=15`，这只表示脚本正确跳过尚无用户 RTL/TB 的题目，不表示 15 题已经通过。

## 验证边界

- Icarus 仿真通过不等于综合、STA 或 CDC 静态检查通过。
- Verible lint 通过不等于功能正确。
- Vivado 当前只记录为“默认 PATH 未找到”，不得写成服务器未安装。
- SVA 支持范围要按具体断言逐项验证，不能由 `-g2012` 编译成功直接推定完整支持。
