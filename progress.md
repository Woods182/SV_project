# 进度板

最近更新：2026-09-02

## 项目级

- PDF 文本提取与逐页目检：VERIFIED（50/50 页）
- 15 题目录和文档骨架：VERIFIED
- 权威执行环境：Arous `/home/ningbin/workspace/SV_project`
- VCS S-2021.09、Verible 与 Yosys 工具链：VERIFIED
- 用户 RTL 完成数：1/15
- self-checking testbench 完成数：1/15
- 工具验收完成数：1/15

## 单题状态

| # | 主题 | 规格 | 参考 | 架构 | 用户 RTL | 用户 TB | 工具验收 |
|---:|---|---|---|---|---|---|---|
| 01 | 异步 FIFO | VERIFIED | VERIFIED | VERIFIED | VERIFIED | VERIFIED | VERIFIED |
| 02 | 偶数/奇数/分数分频 | TODO | TODO | TODO | TODO | TODO | TODO |
| 03 | 上升/下降/双边沿检测 | TODO | TODO | TODO | TODO | TODO | TODO |
| 04 | 序列检测 FSM | TODO | TODO | TODO | TODO | TODO | TODO |
| 05 | 半加器/全加器/多 bit/超前进位 | TODO | TODO | TODO | TODO | TODO | TODO |
| 06 | 固定优先级与轮询仲裁 | TODO | TODO | TODO | TODO | TODO | TODO |
| 07 | Gray/二进制转换 | TODO | TODO | TODO | TODO | TODO | TODO |
| 08 | 门控时钟与唤醒 | TODO | TODO | TODO | TODO | TODO | TODO |
| 09 | 无毛刺时钟切换 | TODO | TODO | TODO | TODO | TODO | TODO |
| 10 | 串并转换 | TODO | TODO | TODO | TODO | TODO | TODO |
| 11 | ready/valid 握手与反压 | TODO | TODO | TODO | TODO | TODO | TODO |
| 12 | 异步复位同步释放 | TODO | TODO | TODO | TODO | TODO | TODO |
| 13 | 模 3 检测 | TODO | TODO | TODO | TODO | TODO | TODO |
| 14 | 多 bit CDC 握手 | TODO | TODO | TODO | TODO | TODO | TODO |
| 15 | 乒乓缓存 | TODO | TODO | TODO | TODO | TODO | TODO |

第 1 题已冻结规格并完成用户 RTL、自检 testbench、Verible lint、VCS 功能仿真和 Yosys 结构检查。PASS 证据及验证边界见 `problems/01_async_fifo/notes.md`。
