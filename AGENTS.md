# test-expert-agent 项目规则

本仓库交付两位 agent——测试设计专家（`@test-expert`，主流程）与测试质检专家（`@test-qa-expert`，subagent，受派发执行全部质检阶段）——及其配套 skills，用于基于项目目录下的研发资产分阶段生成可追溯的测试点与测试用例。语言约定：**所有产出使用中文**。

## 交付物地图

| 路径 | 职责 |
|---|---|
| `.opencode/agents/test-expert.md` | 主流程 agent：流程编排、阶段门禁、状态管理、S1/S3/S5/S7/S9 执行与 TP/TC 修复、质检派发 |
| `.opencode/agents/test-qa-expert.md` | 质检 agent（subagent）：S2/S4/S6/S8 质检；只检不修、不与用户直接交互 |
| `.opencode/skills/test-analysis-methods/` | 分析方法选用矩阵 + 银行/Web/接口专项检查单（S3） |
| `.opencode/skills/prd-quality-check/` | PRD 五维质检 + 锚点规则 + 问题分级（S1/S2） |
| `.opencode/skills/tdd-quality-check/` | 设计材料质检规范：五维 + 前端/后端设计文档、数据字典、接口文档专项（S6） |
| `.opencode/skills/test-point-spec/` | TP 唯一定义源 |
| `.opencode/skills/test-case-spec/` | TC 唯一定义源（含预留变更状态列，当前流程一律留空） |
| `.opencode/skills/self-review-checklist/` | S4/S8 质检清单、问题分级与处置方分类 + validate.sh 硬校验 |
| `qa-workspace/<项目名称>/<功能>/` | 项目材料目录（产品需求文档/开发设计文档/数据字典，只读）+ 功能产物（00-state、01-scope ~ 05-tc-check） |
| `DESIGN.md` | 设计文档：面向团队的工作流与核心要素综述 |

> 历史讨论稿声明：根目录 `notes.md`、`AI测试用例智能生成方案.md`、`设计方案讨论稿.md` 为历史讨论稿，**非权威源**，其内容与当前流程不一致时以本文件、`DESIGN.md` 与 `.opencode/` 为准；这些文件不做修改。

## 必须遵守的约定（对人与未来新增的 agent 均有效）

1. **术语唯一权威源**：TP/TC 定义只在 test-point-spec / test-case-spec；质检规范只在 prd-quality-check / tdd-quality-check / self-review-checklist；其他文件不得另立定义
2. **编号体系**：`TP-<功能码>-NNN` / `TC-<功能码>-NNN`；S1 在 01-scope.md 建立锚点清单表（全流程唯一溯源底册），锚点规则见 prd-quality-check；功能产物目录命名 `<功能码>-<目标功能名称>`
3. **表格列序是校验契约**：03/05 清单模板的列顺序不得调整（validate.sh 按列序校验）
4. **强确认协议**：门禁仅接受 `通过` / `调整@<编号> <说明>` / `退回` 三种答复；Blocker 带风险推进须 `通过 + 阶段名` 二次确认；门禁转移语义见 test-expert 状态机
5. **产物只写 qa-workspace/**：输入材料（PRD/设计文档/数据字典）一律只读；PRD 版本一经 S1 确定全流程锁定，暂不支持修改 PRD 文件（澄清/补充说明除外，且仅登记不落原件）
6. **质检必跑 validate.sh**（落盘模式）：S4 传 `03-test-points.md`、S8 传 `05-test-cases.md`，禁止传 `all`；退出码非 0 禁止定稿
7. **表达四原则**：精炼忌冗长、准确忌歧义、浅显易懂忌黑话术语、边界明确忌模棱两可；面向用户的一切对话与产物正文均适用，允许术语仅限框架已定义术语与 PRD 原文用词
8. **设计文档同步**：修改 `.opencode/agents/` 或任何 `.opencode/skills/` 时，必须同步更新 `DESIGN.md` 对应章节，保持文档与实现一致；仅改 `qa-workspace/` 产物或 `参考资料/` 不触发同步
9. **分层职责（防耦合）**：agent 文件只管流程编排、阶段门禁与状态管理；领域知识（定义、判据、检查单、模板）一律下沉对应 skill 并以其为唯一权威源。跨层与 skill 之间只做指针引用（「规则见 <skill 名>」），禁止复述对方内容；权威源缺失的知识必须先落到 skill 再引用
10. **双 agent 分工**：生成与修复归测试设计专家，检查与结论归测试质检专家；S2/S4/S6/S8 必须派发质检，禁止主 agent 亲自质检自己的产出

## 产物状态与门禁速查

`S1 目标确定 → S2 PRD质检 → S3 识别 → S4 测试点质检 ⇄ S3 修复 → S5 验收 → S6 设计材料质检 → S7 生成 → S8 用例质检 ⇄ S7 修复 → S9 用例评审`

门禁状态（S1/S2/S5/S6/S9）未获用户强确认不得推进；S3↔S4、S7↔S8 为质检修复循环，输入/基线级质检问题须立即呈报用户，连续 3 轮未收敛暂停循环请用户裁定。建议每个门禁通过后 `git commit` 留痕。
