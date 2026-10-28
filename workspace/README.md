# workspace 运行时工作空间

依据 `DESIGN/工作空间目录结构.md` 初始化，为「星云风险管理」项目预置运行时目录骨架。三个测试 agent（`@test-manager` 主流程、`@test-designer` 与 `@test-qa-expert` subagent）已切换到本结构，产物一律写入本目录体系。

## 目录与取值

| 层级 | 取值 | 说明 |
|---|---|---|
| `runtime_<projectId>` | `runtime_星云风险管理` | 应用运行时根，所有会话共用 |
| `<prdId>` | `PRD-第二稿` | 需求目录；需求文档为 `需求平台-产品需求说明书PRD-第二稿.docx`（本地以原件直接存放、保留原文件名；平台态为 `<产品需求文档>` 软链接） |
| `<functionId>` | `XZF-新增风险` | FUNC-01 新增风险，功能码 XZF（沿用功能码-功能名称命名） |
| `session-log/` | 固定名会话目录 | **自包含运行单元**：快照、底册、状态与全部过程产物都在其中；`input/` 存放用户上传资料；重新开始时归档为 `session-log-归档-<日期>` |

## 会话目录内的流程功能文件（由 S1 生成，骨架暂空缺）

- `session-log/prd.txt`：PRD 文本快照（textutil 由原件转换），validate.sh 摘录逐字机验与漏锚扫描基准
- `session-log/scope.md`：功能清单 + 锚点底册（全流程唯一溯源底册）
- `session-log/state.md`：状态登记（PRD 指纹、门禁与确认记录、派发会话）

## 只读输入目录现状

| 目录 | 现状 |
|---|---|
| `develop-docs/fe-docs/` | 已放入 `前端开发设计文档.docx`（自 git 历史恢复） |
| `develop-docs/be-docs/` | 空：后端设计文档未提供（原 S6 缺口「缺-2」） |
| `db-docs/` | 空：`tp-ddl.json`（历史测试点）/ `tc-ddl.json`（历史测试用例）/ `dict-ddl.json`（数标库）待平台按业务功能粒度召回（原 S6 缺口「缺-1」） |
| `domain-knowledge/` | 空：待沉淀 |
| `code/` | 空：待接入 |
| `output/` | 空：S9 评审通过且用户采纳后生成 `bf-tp-tc.json` |

## 生成阶段输入约定（与 agent 派发单一致）

| 阶段 | 必须 | 可选（缺失注明「未提供」，继续生成） |
|---|---|---|
| S3 测试点识别 | 需求文档（需求目录） | domain-knowledge/、db-docs/tp-ddl.json、session-log/input/ |
| S7 用例生成 | develop-docs/ | db-docs/tc-ddl.json、db-docs/dict-ddl.json（数标库，测试数据取值）、domain-knowledge/、session-log/input/ |

> 必须（S3=需求文档、S7=开发设计文档）缺失或为空时，经理暂停请求补充；带风险推进须用户二次确认。

## 与旧 qa-workspace 结构的关系

运行时目录已由 `qa-workspace/<项目>/<功能>/`（00-state、01-scope、00-input、02~05 编号产物）整体切换为上述结构（session-log 自包含运行单元，语义命名）；旧 `qa-workspace/` 已退役删除（git 历史可查，提交 f956c79 前）。validate.sh 以会话目录产物为入口，自动取同目录 `scope.md` 与 `prd.txt`。
