# 异步 FIFO：学习与验证记录

## 用户完成状态

- 用户 RTL `FIFO.sv`：未开始（当前仅有不完整的 `module FIFO`）
- 参考 RTL `FIFO_ref.sv`：已完成
- self-checking TB：已完成，当前验证参考 RTL
- 用户确认的规格：无

## 实际命令与证据

2026-09-02 使用 VCS S-2021.09 运行：

```bash
make clean PROBLEM=01_async_fifo
make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo
```

VCS 仿真结果：

```text
[TEST] empty-read blocking
[TEST] fill/full blocking/drain
[TEST] write-fast/read-slow randomized traffic
[TEST] write-slow/read-fast randomized traffic
[TEST] near-frequency randomized traffic
PASS: writes=144 reads=144 final_occupancy=0
```

波形：`out/01_async_fifo.vcd`；同时生成 VCS KDB/debug 数据库，可供 DVE/Verdi 调试。

此前使用 Icarus 对最小合法参数 `DATA_WIDTH=1, ADDR_WIDTH=1, DEPTH=2` 的复跑结果：

```text
PASS: writes=36 reads=36 final_occupancy=0
```

静态检查：

- `make lint PROBLEM=01_async_fifo`：Verible PASS，0 条告警。
- Yosys `read_verilog/hierarchy/proc/check`：PASS，0 个结构问题。

覆盖：复位启动、空读抑制、满写抑制、完整填满/排空、多个 wrap-around、写快读慢、写慢读快、近频异相、随机空闲、逐 word scoreboard、Gray 指针单 bit 变化检查。

当前 PASS 只证明 RTL 功能仿真；不替代综合、CDC、STA 或门级验证。

## 波形复盘

- 已由 VCS 保存 `out/01_async_fifo.vcd`（96,673 bytes，timescale 1 ps）。
- VCD 包含 TB、DUT、二进制/Gray 指针、两级同步寄存器、RAM、full/empty 和 scoreboard 相关信号。
- 当前仅核验文件有效且来源为 VCS S-2021.09，尚未进行人工 GUI 波形复盘。

## 错误与改进

- 复位契约限定为共同异步拉低、分别同步释放；不支持运行中的单域复位。
- 双时钟数组能否映射为目标 SRAM/BRAM，以及 read-during-write 语义，需要结合具体 ASIC/FPGA 存储宏确认。
- `ASYNC_REG` 属性不能代替 CDC/STA 约束；实现阶段仍需设置 Gray 总线最大延迟/偏斜约束并跑 CDC 工具。
