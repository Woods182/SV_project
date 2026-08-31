# 异步 FIFO：GitHub 检索计划

状态：DRAFT；尚未联网检索，也没有选定参考实现。

## 检索问题

1. 找到经典 Gray-pointer 异步 FIFO 的独立实现与 testbench，而不是只有代码片段的转载。
2. 对比“下一状态 Gray 指针空满判断”与其他写法，核查满判断的高位反转公式和参数边界。
3. 找到包含非同频随机时钟、scoreboard、wrap-around 和 reset 场景的 self-checking 验证。
4. 观察 CDC/综合属性如何按工具隔离，避免把某家 FPGA 属性当成通用 ASIC 语义。

## 建议 GitHub 查询词

- `async fifo systemverilog gray pointer self checking testbench`
- `asynchronous fifo verilog gray code full empty MIT license`
- `async_fifo.sv ASYNC_REG scoreboard`
- `Cummings async FIFO style #2 github`（只作方法来源线索，仍需核实仓库授权）
- 代码检索：`wgraynext ==`、`rgraynext ==`、`$onehot`、`$onehot0`

## 筛选顺序

1. 仓库根目录存在明确 `LICENSE`，并能固定到 commit/tag。
2. RTL 与 TB 分离，测试可复现且是真正 self-checking。
3. 参数化深度和最小位宽有显式检查。
4. 对独立复位、RAM 语义、同步器属性和 CDC 约束有诚实说明。
5. 有 CI/维护记录作为辅助信号，但不把 stars 或“仿真通过”当正确性证明。

## 每个候选的记录模板

| 仓库/文件 | commit/tag | 许可证 | 实现摘要 | 可借鉴点 | 潜在错误/规格差异 | 测试质量 | 采用结论 |
|---|---|---|---|---|---|---|---|
| 待检索 | - | - | - | - | - | - | - |

## 重点审查清单

- 是否错误地同步多 bit 二进制指针。
- Gray 满判断位切片是否只对某一地址宽度成立。
- 使用当前指针还是 next pointer 产生空满，接口延迟是否一致。
- 跨域同步寄存器是否被组合逻辑污染，是否每个域各有两级。
- 复位是否让输出状态安全，单域复位是否造成数据语义未定义却未说明。
- testbench 是否只看波形/打印，还是有真正 scoreboard 和失败退出。
- 是否依赖不可移植的 RAM/initial/vendor primitive，且未与通用实现隔离。

检索结果必须遵守 `docs/reference-policy.md`，第三方代码不得进入用户 `design/01_async_fifo/` 或 `testbench/01_async_fifo/` 手写区。
