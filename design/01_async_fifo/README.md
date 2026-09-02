# 01_async_fifo RTL

状态：VERIFIED（2026-09-02）

- `FIFO.sv`：用户完成的异步 FIFO，默认 filelist 的正式验收对象。
- `FIFO_ref.sv`：独立编写的参考实现，仅用于架构和边界对照。

用户版采用本地二进制指针、跨域 Gray 指针、两级同步器以及寄存式读数据接口。当前冻结规格要求 `DATA_WIDTH >= 1`、`ADDR_WIDTH >= 2`，完整接口和复位契约见 `../../problems/01_async_fifo/spec.md`。
