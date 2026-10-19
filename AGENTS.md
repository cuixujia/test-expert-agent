# test-expert-agent 项目规则

本仓库交付一位资深测试专家 agent（`@test-expert`）及其配套 skills，用于基于研发资产分阶段生成可追溯的测试点与测试用例。语言约定：**所有产出使用中文**。

## 交付物地图

| 路径 | 职责 |
|---|---|
| `.opencode/agents/test-expert.md` | 唯一 agent：流程编排、阶段门禁、状态管理 |
| `.opencode/skills/test-analysis-methods/` | 分析方法选用矩阵 + 银行/Web/接口专项检查单 |
| `.opencode/skills/prd-quality-check/` | 五维质检 + 锚点规则 |
| `.opencode/skills/test-point-spec/` | TP 唯一定义源 |
| `.opencode/skills/test-case-spec/` | TC 唯一定义源（含变更状态预留列） |
| `.opencode/skills/self-review-checklist/` | 自检清单 + validate.sh 硬校验 |
| `.opencode/skills/change-impact-analysis/` | Phase 3 预留骨架（WIP） |
| `qa-workspace/<功能>/` | 运行时产物（01-scope ~ 05-test-cases + 00-state） |
| `DESIGN.md` | 设计文档：面向团队的工作流与核心要素综述 |

## 必须遵守的约定（对人与未来新增的 agent 均有效）

1. **术语唯一权威源**：TP/TC 定义只在 test-point-spec / test-case-spec；其他文件不得另立定义
2. **编号体系**：`TP-<功能码>-NNN` / `TC-<功能码>-NNN`；S1 在 01-scope.md 建立锚点清单表（全流程唯一溯源底册），锚点规则见 prd-quality-check
3. **表格列序是校验契约**：03/05 清单模板的列顺序不得调整（validate.sh 按列序校验）
4. **强确认协议**：门禁仅接受 `通过` / `调整@<编号> <说明>` / `退回` 三种答复
5. **产物只写 qa-workspace/**：输入材料（PRD/设计文档）一律只读
6. **自检必跑 validate.sh**：退出码非 0 禁止提交评审
7. **表达四原则**：精炼忌冗长、准确忌歧义、浅显易懂忌黑话术语、边界明确忌模棱两可；面向用户的一切对话与产物正文均适用，允许术语仅限框架已定义术语与 PRD 原文用词
8. **设计文档同步**：修改 `.opencode/agents/test-expert.md` 或任何 `.opencode/skills/` 时，必须同步更新 `DESIGN.md` 对应章节，保持文档与实现一致；仅改 `qa-workspace/` 产物或 `参考资料/` 不触发同步
9. **分层职责（防耦合）**：agent 文件只管流程编排、阶段门禁与状态管理；领域知识（定义、判据、检查单、模板）一律下沉对应 skill 并以其为唯一权威源。跨层与 skill 之间只做指针引用（「规则见 <skill 名>」），禁止复述对方内容；权威源缺失的知识必须先落到 skill 再引用

## 产物状态与门禁速查

`S1 目标确定 → S2 PRD质检 → S3 识别 → S4 自检 → S5 验收 → S6 设计质检 → S7 生成+自检 → S8 初评审 →（S9 变更分析，Phase 3 预留）`

门禁状态（S2/S5/S6/S8）未获用户强确认不得推进；S1 用户指定目标功能即视为确认，直接进入 S2。建议每个门禁通过后 `git commit` 留痕。
