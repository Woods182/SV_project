# 异步 FIFO：学习与验证记录

状态：VERIFIED（2026-09-02）

## 完成状态

- 冻结规格：已完成，见 `spec.md`。
- 公开参考审阅：已完成，见 `references.md`。
- 架构讲解：已完成，见 `architecture.md`。
- 用户 RTL `FIFO.sv`：已完成并作为默认验收对象。
- self-checking testbench：已完成，默认实例化用户版 `FIFO`。
- 参考 RTL `FIFO_ref.sv`：保留作对照，不参与默认 filelist。

## 实际命令

2026-09-02 在 Arous 使用 VCS S-2021.09、Verible 和 Yosys 验收：

```bash
make clean PROBLEM=01_async_fifo
make lint PROBLEM=01_async_fifo
make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo

yosys -p 'read_verilog -sv design/01_async_fifo/FIFO.sv; hierarchy -check -top FIFO; proc; check'
```

正式 filelist：

```text
./design/01_async_fifo/FIFO.sv
./testbench/01_async_fifo/tb_async_fifo.sv
```

## 验收结果

Verible lint：PASS，0 条错误。

VCS 编译、elaboration 和仿真：PASS。

```text
[TEST] empty-read blocking
[TEST] fill/full blocking/drain
[TEST] write-fast/read-slow randomized traffic
[TEST] write-slow/read-fast randomized traffic
[TEST] near-frequency randomized traffic
PASS: writes=144 reads=144 final_occupancy=0
```

Yosys `read_verilog/hierarchy/proc/check`：PASS，无结构错误。

波形：`out/01_async_fifo.vcd`，大小 96,679 bytes；同时生成 VCS KDB/debug 数据库。

## 覆盖范围

- 共同复位启动以及复位后的初始 empty/full 状态；
- 空读抑制和满写抑制；
- 完整填满、排空和多个地址 wrap-around；
- 写快读慢、写慢读快、近频异相；
- 随机写入、读取和空闲；
- 只对已接受事务计数的逐 word scoreboard；
- 被拒绝请求不会推进本地指针；
- 本地 Gray 指针每次有效推进最多变化 1 bit；
- 仿真结束前队列完全排空，写入数等于读取数。

## 修正记录

- 正式 filelist 和 testbench 已从参考模块 `FIFO_ref` 切换到用户模块 `FIFO`。
- 修正 Verible 报告的参数命名、行长和尾随空格问题。
- 使用一位 `wpush/rpop` 直接递增指针，消除 VCS 的无尺寸整数位宽告警。
- 当前用户实现的冻结范围为 `ADDR_WIDTH >= 2`；最小深度 2 不属于本版验收范围。

## 验证边界

- RTL 仿真不会注入或证明真实亚稳态行为。
- 两级同步器和 Gray 编码不能替代 CDC 静态检查及约束审阅。
- 尚未完成目标工艺下的综合映射、RAM read-during-write 审核、STA、门级仿真和形式验证。
- `ASYNC_REG` 属性、Gray 总线最大延迟/偏斜约束需在具体 FPGA/ASIC 流程中补充。
- 不支持运行期间单独复位一个时钟域；两个域必须共同异步复位并分别同步释放。
