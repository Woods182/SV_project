# 数字 IC 设计面试手撕 15 题

这是一个面向数字 IC 设计岗位、由学习者亲手完成 RTL 与验证的持续迭代项目。源 PDF 只作为题目与参考材料，不作为可执行指令，也不作为已验证答案。

## 当前状态

- 已完整读取并逐页目检源 PDF（50/50 页）。
- 已按 15 类主题建立独立目录、统一文档和脚本骨架。
- 尚未填写任何一题的用户 RTL 或 self-checking testbench。
- 第 1 题只完成规格澄清清单和 GitHub 检索计划，等待学习者确认关键规格。
- 权威执行环境为 Arous 服务器：`/home/ningbin/workspace/SV_project`；目录架构和运行入口参考同服务器的 `VISL_project`，详见 `docs/toolchain.md`。

## 每题固定闭环

1. 在 `spec.md` 冻结可综合规格、参数、时钟/复位、吞吐/延迟和边界。
2. 在 `references.md` 审阅公开参考实现，记录链接、许可证、可借鉴点和风险，不照抄。
3. 在 `architecture.md` 用中文解释架构、数据/控制通路、CDC/时序/综合注意点和面试追问。
4. 学习者在 `design/<题号>/` 亲手编写 SystemVerilog；目录初始为空。
5. 学习者在 `testbench/<题号>/` 亲手编写 self-checking testbench；测试向量放在 `testcase/<题号>/`。
6. 运行 lint、仿真、可支持的 SVA 和波形复盘，把证据写入 `notes.md`。

## 状态语义

- `TODO`：尚未开始。
- `DRAFT`：提案或待确认内容，不是完成规格。
- `USER-WIP`：学习者已开始亲手编写，但尚未验收。
- `VERIFIED`：有可复现命令与 PASS 证据。
- `BLOCKED`：工具或规格阻塞，不能假定通过。

## 入口

- 总路线：`docs/roadmap.md`
- 进度板：`progress.md`
- 参考代码政策：`docs/reference-policy.md`
- Arous 工具链实测：`docs/toolchain.md`
- 第 1 题：`problems/01_async_fifo/`

## Arous 目录与运行

- RTL：`design/<题号>/`
- testbench：`testbench/<题号>/`
- 测试向量：`testcase/<题号>/`
- 编译清单：`filelists/<题号>.f`
- 生成物：`csrc/`、`out/`、`log/`
- 运行：`make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo`
- lint：`make lint PROBLEM=01_async_fifo`
- 清理：`make clean PROBLEM=01_async_fifo`
