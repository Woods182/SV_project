# 第一题工程：异步 FIFO

状态：VERIFIED（2026-09-02）

第 1 题已完成冻结规格、公开参考审阅、架构说明、用户 RTL、自检 testbench 和 RTL 级工具验收。

## 文件入口

- 冻结规格：`spec.md`
- 架构说明：`architecture.md`
- 参考审阅：`references.md`
- 验证记录：`notes.md`
- 用户 RTL：`../../design/01_async_fifo/FIFO.sv`
- 参考 RTL：`../../design/01_async_fifo/FIFO_ref.sv`
- 自检 TB：`../../testbench/01_async_fifo/tb_async_fifo.sv`
- 编译清单：`../../filelists/01_async_fifo.f`

默认 filelist 已切换到用户版 `FIFO.sv`；`FIFO_ref.sv` 仅用于架构比较，不参与默认验收。

## 复现命令

```bash
make clean PROBLEM=01_async_fifo
make lint PROBLEM=01_async_fifo
make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo
```

期望结果：

```text
PASS: writes=144 reads=144 final_occupancy=0
```

验证覆盖与尚未完成的 CDC、STA、门级验证等边界见 `notes.md`。
