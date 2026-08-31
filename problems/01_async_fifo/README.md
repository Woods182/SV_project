# 第一题工程：异步 FIFO

状态：规格确认阶段；尚无用户 RTL、testbench 或功能 PASS。

## Arous 工作位置

- 项目根目录：`/home/ningbin/workspace/SV_project`
- Git 分支：`problem/01_async_fifo`
- 用户 RTL：`design/01_async_fifo/`
- 用户 TB：`testbench/01_async_fifo/`
- 测试向量：`testcase/01_async_fifo/`
- 编译清单：`filelists/01_async_fifo.f`
- 规格与讲解：本目录

## 当前阶段

1. 阅读并确认 `spec.md` 的接口、时钟、复位、吞吐、延迟和边界。
2. 规格冻结后，再完成 `references.md` 中的 GitHub 检索与许可证审阅。
3. 在 `architecture.md` 讲清数据通路、控制/指针通路、CDC、空满判断和综合注意点。
4. 由学习者亲手编写 RTL 和 self-checking TB。
5. 在 Arous 上运行 lint、仿真和波形复盘，并将真实证据写入 `notes.md`。

## 运行入口

```bash
cd /home/ningbin/workspace/SV_project

make list PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo
make lint PROBLEM=01_async_fifo
make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo
make clean PROBLEM=01_async_fifo
```

当前 `filelists/01_async_fifo.f` 为空，因此命令应明确报告 `SKIP`；这不是题目通过。

## 待用户确认的推荐基线

- `DATA_WIDTH=8`，深度 16，并将深度限定为 2 的幂。
- 标准读接口，不采用 FWFT/show-ahead。
- `wr_clk`、`rd_clk` 完全异步。
- `wr_rst_n`、`rd_rst_n` 低有效异步复位，各自在本域同步释放。
- 第一版只实现 `full/empty`；满写和空读不接受。
- 每个时钟域峰值吞吐为 1 word/clock。
- 本地二进制指针、跨域 Gray 指针、两级同步器。
- 通用可综合 SystemVerilog，不绑定 FPGA BRAM 或 ASIC SRAM 宏。

读数据延迟、`rd_valid`、`wr_accept`、单域复位语义、复位后状态有效周期和最小合法 `ADDR_WIDTH` 仍需明确确认。
