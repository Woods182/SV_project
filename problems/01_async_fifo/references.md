# 异步 FIFO：公开参考实现审阅

状态：REVIEWED（检索日期：2026-09-02）

本题只借鉴架构和验证思路，`FIFO_ref.sv` 与 testbench 为独立重写，未粘贴第三方实现。

## 源材料

- 本地 PDF：`common/2_手撕代码15道.pdf`，第 5-7 页及第 42-47 页。
- 采用要点：读写二进制指针扩展一位、Gray 编码跨域、两级同步、读域判空、写域判满，以及 CDC 保守延迟。
- 审阅意见：PDF 的满判断公式适用于经典 2 的幂深度，但代码片段没有完整接口、参数检查、复位契约和 self-checking TB，不能直接作为可验证实现。

## GitHub 候选 1：dpretet/async_fifo

- 仓库：https://github.com/dpretet/async_fifo
- 固定 commit：`38c22208d3948833f275b917c920e02b1cdadf56`
- 主要文件：
  - https://github.com/dpretet/async_fifo/blob/38c22208d3948833f275b917c920e02b1cdadf56/rtl/async_fifo.v
  - https://github.com/dpretet/async_fifo/blob/38c22208d3948833f275b917c920e02b1cdadf56/rtl/wptr_full.v
  - https://github.com/dpretet/async_fifo/blob/38c22208d3948833f275b917c920e02b1cdadf56/rtl/rptr_empty.v
- 作者/组织：Damien Pretet / dpretet
- 许可证：MIT，https://github.com/dpretet/async_fifo/blob/38c22208d3948833f275b917c920e02b1cdadf56/LICENSE
- 实现范围：经典 Gray-pointer 异步 FIFO，包含标准/FWFT 读模式、almost-full/empty 和仿真环境。
- 可借鉴点：用 `next` 二进制/Gray 指针生成寄存的 full/empty；只同步 Gray 指针；内存地址仍使用本地二进制指针。
- 风险/规格差异：功能比本题多；其 `ADDRSIZE-2:0` 满判断切片对最小参数不友好；almost-empty 代码命名/计算需要单独审查；不能直接移入手写区。
- 采用结论：采用 next-pointer 判定思路，不采用代码和扩展功能。

## GitHub 候选 2：pulp-platform/common_cells

- 仓库：https://github.com/pulp-platform/common_cells
- 固定 commit：`db42769334b4589b4b3fc671b34513bdb98be565`
- 主要文件：
  - https://github.com/pulp-platform/common_cells/blob/db42769334b4589b4b3fc671b34513bdb98be565/src/cc_cdc_fifo_gray.sv
  - https://github.com/pulp-platform/common_cells/blob/db42769334b4589b4b3fc671b34513bdb98be565/test/cc_cdc_fifo_gray_tb.sv
- 作者/组织：ETH Zurich、University of Bologna / PULP Platform
- 许可证：Solderpad Hardware License 0.51（允许按 Apache-2.0 处理），https://github.com/pulp-platform/common_cells/blob/db42769334b4589b4b3fc671b34513bdb98be565/LICENSE
- 实现范围：工业化参数化 Gray CDC FIFO，ready/valid 接口、可配置同步级数、断言、延迟注入测试和约束说明。
- 可借鉴点：明确要求深度为 `2**LogDepth`、同步级数至少 2；强调复位必须共同异步拉低、分别同步释放；TB 使用 transaction queue、随机背压、Gray 单 bit 变化检查和 wrap-around。
- 风险/规格差异：依赖 `common_cells` 宏、类型参数、同步单元及工程约束；其输出接口是 ready/valid/FWFT 风格，不等同于本题的寄存读接口。
- 采用结论：采用复位契约、参数边界和验证覆盖思路，不采用代码及依赖。

## 本项目采用结论

`FIFO_ref.sv` 固定为以下教学规格：

- `DATA_WIDTH` 与 `ADDR_WIDTH` 参数化，`DEPTH=2**ADDR_WIDTH`，最小深度 2。
- 写入仅在 `winc && !wfull` 时接受，读取仅在 `rinc && !rempty` 时接受。
- 标准寄存读：成功读取后 `rdata` 更新，其他时间保持。
- 每个方向使用两级 Gray 指针同步器；二进制指针不跨域。
- full 使用同步读 Gray 指针最高两位反转比较；实现为 XOR mask，以覆盖 `ADDR_WIDTH=1`。
- 不支持单域 warm reset/flush；两域复位应共同拉低并分别同步释放。
