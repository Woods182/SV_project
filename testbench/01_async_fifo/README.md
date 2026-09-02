# 01_async_fifo self-checking testbench

状态：VERIFIED（2026-09-02）

`tb_async_fifo.sv` 是默认验收 testbench，当前实例化用户版 `FIFO.sv`。TB 自动维护 transaction queue、逐 word 比较读写顺序、统计错误并输出 PASS/FAIL；波形写入 `out/01_async_fifo.vcd`，日志写入 `log/`。

本次 RTL 仿真覆盖并证明：

- 空 FIFO 不会接受读请求。
- 满 FIFO 不会接受写请求。
- 写满 8 个数据后 `wfull` 正确拉高。
- 读空后 `rempty` 正确拉高。
- 读出顺序和写入顺序一致。
- 写时钟快于读时钟可以工作。
- 读时钟快于写时钟可以工作。
- 两个时钟频率相近时可以工作。
- 指针多次回卷后数据仍然正确。
- 满、空状态下指针不会错误前进。
- 本地 Gray 指针每次最多改变一个 bit。

这些结果只覆盖当前 RTL 参数与仿真场景，不代替真实亚稳态分析、CDC、STA、综合映射或门级验证。
