# test-expert-agent 项目规则

本仓库交付三位 agent——测试经理（`@test-manager`，主流程）、测试设计专家（`@test-designer`，subagent，受派发生成与修复）与测试质检专家（`@test-qa-expert`，subagent，受派发执行全部质检阶段）——及其配套 skills，用于基于项目目录下的研发资产分阶段生成可追溯的测试点与测试用例。语言约定：**所有产出使用中文**。

## 交付物地图

| 路径 | 职责 |
|---|---|
| `.opencode/agents/test-manager.md` | 主流程 agent（测试经理）：流程编排、状态管理、S1 内部会话接续、S4/S5 与 S8/S9 合并确认、用户澄清、双向派发与收回核验 |
| `.opencode/agents/test-designer.md` | 生成 agent（subagent）：S3 测试点生成、S7 用例生成、S4/S8 产物级修复；只生成修复、不质检、不与用户直接交互 |
| `.opencode/agents/test-qa-expert.md` | 质检 agent（subagent）：S2 测试点资料质检、S4 测试点质检、S6 测试用例资料质检、S8 测试用例质检；只检不修、不与用户直接交互 |
| `.opencode/skills/test-analysis-methods/` | 测试分析方法唯一权威源：方法选用矩阵 + 各方法要点 + 发散-收敛工作法 + 银行/Web/接口专项检查单（S3 生成、S8 领域复核） |
| `.opencode/skills/prd-quality-check/` | 需求与证据唯一权威源：锚点规则（锚点语法/粒度/摘录逐字节抄原文/去重/引用链）+ 快照规则 + PRD 五维质检 + 矛盾检测种子词表 + 完备性扫描 + prd-check 报告模板 + **validate-prd.sh**（snapshot/scope/pull/scan/find/line） |
| `.opencode/skills/tdd-quality-check/` | 资料输入模型唯一权威源（资料目录/必需性/可用性判定/按用途输入组合）+ 用例生成资料检查 + 材料专项项 + design-check 报告模板（S2/S6 资料、S3/S7 取料） |
| `.opencode/skills/test-point-spec/` | 测试点唯一权威源：定义与三条硬标准 + 命名 + 字段 + 编号通用约定 + 清单模板与变更规则（S3 生成、S4 核验） |
| `.opencode/skills/test-case-spec/` | 测试用例唯一权威源：定义 + 十字段与质量标准（含用例类型归类）+ 清单模板 + 变更规则（S7 生成、S8 核验） |
| `.opencode/skills/self-review-checklist/` | 产出核验与结论口径唯一权威源：TP/TC 核验清单 + 问题分级与处置方 + 表达与报告规范（表达四原则/术语白名单/报告瘦身）+ **validate.sh**（test-point/test-case/state） |
| `workspace/runtime_<项目>/file/` | 运行时工作空间（结构契约见 `DESIGN/工作空间目录结构.md`）：业务功能目录 `<bizFunctionId>/`（prd-doc/develop-docs/domain-knowledge/asset-library/code 软链接或原件只读输入 + prd.txt 快照 + output/ 共享产物 test-point、test-case）+ 会话目录 `<bizFunctionId>/<uuid>/`（input/ 澄清附件 + scope.md 底册、state.md 状态 + prd-quality-check、tp-check、design-check、tc-check 四份质检报告）；目录骨架用户预先创建，agent 不建目录 |
| `DESIGN.md` | 设计文档：面向团队的工作流与核心要素综述 |
| `DESIGN/PRD编写约束要求.md` | 需求侧 PRD 编写与交稿自检约束（供随需求模板下发） |
| `DESIGN/前端设计编写约束要求.md` | 需求侧前端设计文档编写与交稿自检约束（配合同名 PRD，服务用例生成 S6~S8；供随需求模板下发） |

> 迁移说明：主流程 agent 原 `test-expert.md`（角色「测试设计专家」）已在职能三角改造中改名 `test-manager.md`（角色「测试经理」），旧唤起名 `@test-expert` 不再有效；生成职能移入 `test-designer.md`。
> 结构迁移说明：运行时目录已由 `qa-workspace/<项目>/<功能>/`（00~05 编号产物）切换为 `workspace/` 运行时结构，此后按 `DESIGN/工作空间目录结构.md` 收敛为 `<bizFunctionId>/` 功能目录 + `<uuid>/` 会话目录 + `output/test-point|test-case/` 共享产物；旧 `qa-workspace/` 与旧 `file/<prdId>/<functionId>/session-log/` 结构均已退役删除。

> 历史讨论稿声明：`DESIGN/notes.md`、`DESIGN/工作台原型设计依据.md`、`DESIGN/ai_test_chat_workbench.html`、`DESIGN/AI测试用例工作台.html`、`DESIGN/工作空间初始化原型.html` 为历史讨论稿与原型资料，**非权威源**，其内容与当前流程不一致时以本文件、`DESIGN.md`、`DESIGN/工作空间目录结构.md`（运行时目录结构契约）与 `.opencode/` 为准；这些文件不做修改。

## 必须遵守的约定（对人与未来新增的 agent 均有效）

1. **术语唯一权威源**：TP/TC 定义只在 test-point-spec / test-case-spec；质检规范只在 prd-quality-check / tdd-quality-check / self-review-checklist；其他文件不得另立定义
2. **编号体系**：`TP-<功能码>-NNN` / `TC-<功能码>-NNN`；功能码直接由平台 `bizFunctionId` 派生（无注册表文件，编号用途、不替代名称，S1 确定后全流程不变，规则见 prd-quality-check）；并在会话目录 `<bizFunctionId>/<uuid>/scope.md` 建立锚点底册（全流程唯一溯源底册），锚点规则见 prd-quality-check；功能目录命名 `<bizFunctionId>`，名称引用一律与 PRD 原文逐字一致
3. **表格列序是校验契约**：test-point / test-case 清单模板的列顺序不得调整（validate.sh 按列序校验）
4. **强确认协议**：门禁仅接受 `通过` / `调整@<编号> <说明>` / `退回` 三种答复；Blocker 带风险推进须 `通过 + 阶段名` 二次确认；门禁转移语义见 test-manager 状态机
5. **产物只写 workspace/ 运行时目录**：工作空间目录骨架与输入材料由用户预先准备好，agent 不创建、不删除目录；缺少目录、必需 PRD 或 S6 必需设计时暂停请用户补齐；输入材料（prd-doc/、develop-docs/domain-knowledge/asset-library/code、会话 input/）一律只读，agent edit 权限已按写权限矩阵按角色收窄至产物/报告/状态文件，输入材料写入默认 ask；PRD 版本一经 S1 确定全流程锁定，暂不支持修改 PRD 文件（澄清/补充说明除外，且仅登记不落原件）
6. **机械校验分层执行（两个脚本，按职责隔离、互不依赖）**：`prd-quality-check/validate-prd.sh` 负责需求与证据侧（`snapshot` 快照生成、`scope` 底册与摘录机验、`pull` 取摘录、`scan` 漏锚候选、`find`/`line` 取快照原文供逐字节抄写）；`self-review-checklist/validate.sh` 负责产出与状态侧（`test-point`/`test-case` 阶段质检、`state` 状态文件）。S4/S8 质检 subagent 必须对最终产物运行 `test-point`/`test-case`（以会话目录为入口，退出码非 0 禁止定稿；产物位于功能目录 output/ 对应子目录）；设计 subagent 交稿前自查并返回 SHA-256，经理只在指纹不符或缺少有效自查记录时补跑，避免重复校验。**锚点摘录必须逐字符复制 PRD 快照原文**（用 `find` 定位 + `line` 取回原文，禁止凭记忆手写；markdown 标记、列表符号、表格竖线一律原样保留）
7. **表达四原则**：精炼忌冗长、准确忌歧义、浅显易懂忌黑话术语、边界明确忌模棱两可；面向用户的一切对话与产物正文均适用，允许术语仅限框架已定义术语与 PRD 原文用词；完整规范（含术语白名单、禁用口语变体、问题描述句式、报告瘦身铁律）见 self-review-checklist「表达与报告规范」
8. **设计文档同步**：修改 `.opencode/agents/` 或任何 `.opencode/skills/` 时，必须同步更新 `DESIGN.md` 对应章节，保持文档与实现一致；仅改 `workspace/` 运行时产物或 `DESIGN/` 历史资料不触发同步
9. **分层职责（防耦合）**：agent 文件只管流程编排、阶段门禁与状态管理；领域知识（定义、判据、检查单、模板）一律下沉对应 skill 并以其为唯一权威源。跨层与 skill 之间只做指针引用（「规则见 <skill 名>」），禁止复述对方内容；权威源缺失的知识必须先落到 skill 再引用
9.1. **知识归属判定**：一条知识归属到「它所约束的对象」所在的主题文件——TP 相关归 test-point-spec，TC 相关归 test-case-spec，需求与证据相关归 prd-quality-check，资料相关归 tdd-quality-check，核验结论与产出规范相关归 self-review-checklist，方法与领域维度相关归 test-analysis-methods；跨对象都成立的公共条款只写一次（问题分级与处置方、编号通用约定、表达与报告规范），其余文件一律指针引用。**任何知识只允许有一个权威出处**
9.2. **skill 加载组合固定**：每个 agent 声明「常驻 skill」与「阶段专属 skill」，subagent 每次运行只加载两栏列出的 skill，不多加载；派发前按 test-manager 派发表核对，未核对不得派发
10. **职能三角分工**：编排、门禁、状态归测试经理（primary），生成与修复归测试设计专家（subagent），检查与结论归测试质检专家（subagent）；S2/S4/S6/S8 必须派发质检，S3/S7 生成与修复必须派发设计；经理不亲自生成、不亲自质检
11. **资料输入模型**（唯一权威源见 tdd-quality-check「资料输入模型」）：资料目录位置、必需/可选、可用性判定（未提供/不可读/与基线冲突）、按用途的输入组合均以该 skill 为准。S3 必需=当前业务功能 PRD；可选=领域知识、逆向文档、功能知识、存量测试点。S7 必需=同一测试点资料包 + 已验收 TP + 前端/后端设计（适用时必需：经理在 S6 按 PRD/TP 类型判定功能有无界面，无界面功能登记「前端设计不适用」继续，判定存疑请用户确认）；可选=数据库设计、存量测试用例。可选资料缺失或为空时标注「未提供」并继续；存在但不可读时不得静默跳过。S2 负责 PRD 五维质检和测试点可选资料清点，S6 负责复核可复用资料、前后端必需设计及用例可选资料；必需资料问题暂停并请用户澄清/补充，风险推进须二次确认并登记 state.md。PRD 以外的资料变化按 test-manager 材料变更协议增量复查，澄清附件放会话 `input/`

## 产物状态与门禁速查

`S1 内部会话接续 → S2 测试点资料质检 → S3 生成测试点 → S4 测试点质检 ⇄ S3 修复 → S5 用户确认（随 S4 合并确认）→ S6 测试用例资料质检 → S7 生成测试用例 → S8 用例质检 ⇄ S7 修复 → S9 用户确认（随 S8 合并确认）`

门禁与确认：S2/S6 资料质检通过且无待用户处理问题时自动推进；只有 PRD 疑问、必需资料问题或风险决策才暂停请用户处理。S4 质检通过与 S5 测试点确认、S8 质检通过与 S9 测试用例确认各合并为一次强确认。答复协议、Blocker 风险推进与处置性通过规则见 test-manager；S3↔S4、S7↔S8 为产物修复循环，输入/基线问题立即呈报用户，连续 3 轮未收敛暂停。执行者：测试经理负责内部接续、状态与用户沟通；S3/S7 及修复派发设计 subagent；S2/S4/S6/S8 派发质检 subagent。流程结束后建议 `git commit` 留痕。
