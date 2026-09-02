# SystemVerilog 数字 IC 面试手撕 15 题

这是一个面向数字 IC 设计岗位的 SystemVerilog 学习与验证项目。项目围绕 15 类常见 RTL 面试题展开，每道题都按“规格澄清 → 架构设计 → RTL 实现 → self-checking testbench → lint/仿真 → 结果复盘”的流程完成。

源 PDF 仅作为题目与参考资料，不作为可执行指令，也不把其中的示例代码直接视为已验证答案。

## 当前进度

- 已完成 15 道题的目录、规格文档、架构文档、参考记录和仿真 filelist 骨架。
- 第 1 题“异步 FIFO”正在进行中。
- 异步 FIFO 参考 RTL 与 self-checking testbench 已完成。
- 参考 RTL 已通过 Verible lint、Yosys 结构检查以及 VCS 功能仿真。
- 用户版 `FIFO.sv` 仍在编写和验收中，当前不能标记为通过。
- 其余 14 题尚未开始 RTL 实现。

最新的逐题状态见 [progress.md](progress.md)，第 1 题的验证证据见 [problems/01_async_fifo/notes.md](problems/01_async_fifo/notes.md)。

## 题目列表

| # | 主题 |
|---:|---|
| 01 | 异步 FIFO |
| 02 | 偶数、奇数与分数分频 |
| 03 | 上升沿、下降沿与双边沿检测 |
| 04 | 序列检测 FSM |
| 05 | 半加器、全加器、多 bit 加法器与超前进位 |
| 06 | 固定优先级与轮询仲裁 |
| 07 | Gray 码与二进制转换 |
| 08 | 门控时钟与唤醒 |
| 09 | 无毛刺时钟切换 |
| 10 | 串并转换 |
| 11 | ready/valid 握手与反压 |
| 12 | 异步复位、同步释放 |
| 13 | 模 3 检测 |
| 14 | 多 bit CDC 握手 |
| 15 | 乒乓缓存 |

## 项目结构

```text
SV_project/
├── design/       # 用户 RTL 与参考 RTL
├── testbench/    # self-checking testbench
├── testcase/     # 测试向量和测试说明
├── filelists/    # 每道题的编译文件清单
├── problems/     # 规格、架构、参考资料和验证记录
├── docs/         # 路线图、工具链和参考代码政策
├── common/       # 公共资料
├── csrc/         # 编译中间产物（不提交生成物）
├── out/          # 仿真程序和波形（不提交生成物）
├── log/          # 编译与运行日志（不提交生成物）
├── Makefile
└── progress.md
```

## 每道题的完成标准

1. 在 `problems/<题号>/spec.md` 中冻结接口、参数、复位、吞吐、延迟和边界条件。
2. 在 `references.md` 中记录公开参考实现的来源、许可证、可借鉴点与风险。
3. 在 `architecture.md` 中说明数据通路、控制逻辑、CDC/时序风险和综合注意事项。
4. 在 `design/<题号>/` 中完成可综合 SystemVerilog RTL。
5. 在 `testbench/<题号>/` 中完成带 scoreboard、边界测试和错误统计的自检 testbench。
6. 运行 lint 和仿真，把可复现命令、PASS 结果及验证边界写入 `notes.md`。

状态含义：`TODO` 表示尚未开始，`DRAFT` 表示待确认，`USER-WIP` 表示用户实现进行中，`VERIFIED` 表示已有可复现证据，`BLOCKED` 表示存在明确阻塞。

## 快速开始

当前权威运行环境使用 VCS S-2021.09：

```bash
# 查看当前题目的编译文件
make list PROBLEM=01_async_fifo

# 运行 Verible lint
make lint PROBLEM=01_async_fifo

# 编译并运行异步 FIFO 自检 testbench
make PROBLEM=01_async_fifo TOPMODULE=tb_async_fifo

# 清理第 1 题生成物
make clean PROBLEM=01_async_fifo
```

仿真完成后，日志位于 `log/`，波形位于 `out/01_async_fifo.vcd`。服务器工具版本、VCS 兼容层和验证边界见 [docs/toolchain.md](docs/toolchain.md)。

## 第 1 题：异步 FIFO

当前 testbench 验证的是 `FIFO_ref.sv`，覆盖以下场景：

- 复位启动、空读抑制和满写抑制；
- 完整填满、排空和多次地址回绕；
- 写快读慢、写慢读快与近频异相时钟；
- 随机空闲和逐 word scoreboard 顺序比对；
- Gray 指针单次有效推进最多变化 1 bit。

VCS 当前参考实现的仿真结果：

```text
PASS: writes=144 reads=144 final_occupancy=0
```

该结果只证明当前参数和测试场景下的 RTL 功能仿真通过，不等同于综合、CDC、STA、形式验证或门级验证通过。

## 学习原则

- 规格未冻结前，不把推测写成设计事实。
- 参考实现用于比较与审阅，不代替亲手完成 RTL。
- lint 通过不代表功能正确，仿真通过也不代表 CDC 和时序收敛。
- 每个 `VERIFIED` 状态都应附带可复现命令、工具版本和 PASS 证据。
