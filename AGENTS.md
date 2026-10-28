# test-expert-agent 项目规则

本仓库交付三位 agent——测试经理（`@test-manager`，主流程）、测试设计专家（`@test-designer`，subagent，受派发生成与修复）与测试质检专家（`@test-qa-expert`，subagent，受派发执行全部质检阶段）——及其配套 skills，用于基于项目目录下的研发资产分阶段生成可追溯的测试点与测试用例。语言约定：**所有产出使用中文**。

## 交付物地图

| 路径 | 职责 |
|---|---|
| `.opencode/agents/test-manager.md` | 主流程 agent（测试经理）：流程编排、阶段门禁、状态管理、S1 执行、S4/S5 与 S8/S9 合并确认发起、双向派发与收回核验 |
| `.opencode/agents/test-designer.md` | 生成 agent（subagent）：S3 测试点识别、S7 用例生成、S4/S8 产物级修复；只生成修复、不质检、不与用户直接交互 |
| `.opencode/agents/test-qa-expert.md` | 质检 agent（subagent）：S2/S4/S6/S8 质检；只检不修、不与用户直接交互 |
| `.opencode/skills/test-analysis-methods/` | 分析方法选用矩阵 + 银行/Web/接口专项检查单（S3） |
| `.opencode/skills/prd-quality-check/` | PRD 五维质检 + 锚点规则 + 问题分级（S1/S2） |
| `.opencode/skills/tdd-quality-check/` | 设计材料质检规范：五维 + 前端/后端设计文档、数标库、接口文档专项（S6） |
| `.opencode/skills/test-point-spec/` | TP 唯一定义源 |
| `.opencode/skills/test-case-spec/` | TC 唯一定义源（含预留变更状态列，当前流程一律留空） |
| `.opencode/skills/self-review-checklist/` | S4/S8 质检清单、问题分级与处置方分类 + validate.sh 硬校验 |
| `workspace/runtime_<项目>/assets/<prdId>/<functionId>/` | 运行时工作空间（结构契约见 `DESIGN/工作空间目录结构.md`）：需求目录（需求文档软链接，保留原文件名，只读）+ 功能目录（develop-docs/db-docs/domain-knowledge/code 只读输入 + output/ 采纳产物）+ 会话目录 session-log/（自包含运行单元：input/ 用户上传 + prd.txt 快照、scope.md 底册、state.md 状态 + prd-check、test-point、tp-check、design-check、test-case、tc-check 六个过程产物） |
| `DESIGN.md` | 设计文档：面向团队的工作流与核心要素综述 |

> 迁移说明：主流程 agent 原 `test-expert.md`（角色「测试设计专家」）已在职能三角改造中改名 `test-manager.md`（角色「测试经理」），旧唤起名 `@test-expert` 不再有效；生成职能移入 `test-designer.md`。
> 结构迁移说明：运行时目录已由 `qa-workspace/<项目>/<功能>/`（00~05 编号产物）整体切换为 `workspace/` 运行时结构（scope/state/session-log 语义命名，validate.sh 按会话目录自动推导底册与快照）；旧 `qa-workspace/` 已退役删除。

> 历史讨论稿声明：`DESIGN/notes.md`、`DESIGN/工作台原型设计依据.md`、`DESIGN/ai_test_chat_workbench.html` 为历史讨论稿与原型资料，**非权威源**，其内容与当前流程不一致时以本文件、`DESIGN.md`、`DESIGN/工作空间目录结构.md`（运行时目录结构契约）与 `.opencode/` 为准；这些文件不做修改。

## 必须遵守的约定（对人与未来新增的 agent 均有效）

1. **术语唯一权威源**：TP/TC 定义只在 test-point-spec / test-case-spec；质检规范只在 prd-quality-check / tdd-quality-check / self-review-checklist；其他文件不得另立定义
2. **编号体系**：`TP-<功能码>-NNN` / `TC-<功能码>-NNN`；S1 在会话目录 session-log/scope.md 建立锚点清单表（全流程唯一溯源底册），锚点规则见 prd-quality-check；功能目录（functionId）命名 `<功能码>-<目标功能名称>`
3. **表格列序是校验契约**：test-point / test-case 清单模板的列顺序不得调整（validate.sh 按列序校验）
4. **强确认协议**：门禁仅接受 `通过` / `调整@<编号> <说明>` / `退回` 三种答复；Blocker 带风险推进须 `通过 + 阶段名` 二次确认；门禁转移语义见 test-manager 状态机
5. **产物只写 workspace/ 运行时目录**：输入材料（需求文档、develop-docs/db-docs/domain-knowledge/code、会话 input/）一律只读；PRD 版本一经 S1 确定全流程锁定，暂不支持修改 PRD 文件（澄清/补充说明除外，且仅登记不落原件）
6. **质检必跑 validate.sh**：S4 传会话目录 `test-point.md`、S8 传 `test-case.md`，禁止传 `all`；退出码非 0 禁止定稿
7. **表达四原则**：精炼忌冗长、准确忌歧义、浅显易懂忌黑话术语、边界明确忌模棱两可；面向用户的一切对话与产物正文均适用，允许术语仅限框架已定义术语与 PRD 原文用词
8. **设计文档同步**：修改 `.opencode/agents/` 或任何 `.opencode/skills/` 时，必须同步更新 `DESIGN.md` 对应章节，保持文档与实现一致；仅改 `workspace/` 运行时产物或 `DESIGN/` 历史资料不触发同步
9. **分层职责（防耦合）**：agent 文件只管流程编排、阶段门禁与状态管理；领域知识（定义、判据、检查单、模板）一律下沉对应 skill 并以其为唯一权威源。跨层与 skill 之间只做指针引用（「规则见 <skill 名>」），禁止复述对方内容；权威源缺失的知识必须先落到 skill 再引用
10. **职能三角分工**：编排、门禁、状态归测试经理（primary），生成与修复归测试设计专家（subagent），检查与结论归测试质检专家（subagent）；S2/S4/S6/S8 必须派发质检，S3/S7 生成与修复必须派发设计；经理不亲自生成、不亲自质检
11. **S3/S7 输入模型**：S3 必须=需求文档，S7 必须=开发设计文档（develop-docs/）；领域知识（domain-knowledge/）、历史测试点（db-docs/tp-ddl.json）、历史测试用例（db-docs/tc-ddl.json）、数标库（db-docs/dict-ddl.json）、用户上传资料（session-log/input/）均为可选——可选缺失或为空注明「未提供」继续生成，必须材料缺失暂停请求补充（带风险推进须二次确认，state.md 登记后 S7 派发放行）

## 产物状态与门禁速查

`S1 目标确定 → S2 PRD质检 → S3 识别 → S4 测试点质检 ⇄ S3 修复 → S5 验收（随 S4 合并确认）→ S6 设计材料质检 → S7 生成 → S8 用例质检 ⇄ S7 修复 → S9 用例评审（随 S8 合并确认）`

门禁与确认：S1/S2/S6 为独立门禁，S4 质检通过与 S5 验收、S8 质检通过与 S9 评审各合并为一次强确认（质检结论 + 验收/评审一屏完成），未获用户强确认不得推进；S3↔S4、S7↔S8 为质检修复循环，输入/基线级质检问题须立即呈报用户，连续 3 轮未收敛暂停循环请用户裁定。执行者：S1 归测试经理，S5/S9 随 S4/S8 合并确认完成，S3/S7 及其修复派发设计 subagent，S2/S4/S6/S8 派发质检 subagent（分工见约定 10）。建议每个门禁通过后 `git commit` 留痕。
