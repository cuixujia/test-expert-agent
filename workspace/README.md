# workspace 运行时工作空间

依据 `DESIGN/工作空间目录结构.md` 初始化，为「星云风险管理」项目预置运行时目录骨架。

## 平台路径 → 本地路径映射

| 平台定义 | 本地取值 | 依据 |
|---|---|---|
| `/home/instance/workspace/<userId>/<agentId>/` | `workspace/`（仓库根，单用户本地态） | 本地初始化省略 userId/agentId 层级 |
| `runtime_<projectId>` | `runtime_星云风险管理` | 项目名称 |
| `<prdId>` | `PRD-第二稿` | 权威 PRD：`qa-workspace/星云风险管理/产品需求文档/需求平台-产品需求说明书PRD-第二稿.docx`（与 `qa-workspace/星云风险管理/XZF-新增风险/00-state.md` 指纹登记一致） |
| `<functionId>` | `XZF-新增风险` | FUNC-01 新增风险，功能码 XZF（沿用 `01-scope.md` 功能清单与既有产物目录命名） |
| `<uuid>` | `60a4d605-ed3f-42ef-b153-79969b6fc749` | 本次初始化预建的空会话，后续会话各建一个 |

## 软链接说明（只读，指向 qa-workspace 源材料）

| 链接 | 指向 |
|---|---|
| `assets/PRD-第二稿/prd.md` | 权威 PRD 原件（.docx）。平台态为需求文档的 md 版本，本地暂以原件软链接代替 |
| `assets/PRD-第二稿/XZF-新增风险/develop-docs/fe-docs/前端开发设计文档.docx` | `qa-workspace/星云风险管理/开发设计文档/前端开发设计文档.docx` |

## 占位说明（待接入，当前为空目录）

- `develop-docs/be-docs/`：后端设计文档（对应 S6 缺口「缺-2」，未提供）
- `db-docs/`：`tc-ddl.json`（用例库）/ `dict-ddl.json`（数标库），待平台按业务功能粒度召回（对应 S6 缺口「缺-1」数据字典）
- `domain-knowledge/`：按业务领域沉淀的领域知识，待沉淀
- `code/`：代码工程，待接入
- `output/`：用户确认采纳后生成 `bf-tp-tc.json`（业务功能-测试点-测试用例集）
- `runtime_星云风险管理/.opencode/`：`agent/`、`tool/`、`skills/` 为用户自定义运行时配置，当前为空
- `<uuid>/` 下 6 个过程文件为空占位，由各阶段执行时写入；`input/` 存放本次会话附带输入

## 与 qa-workspace 的关系

`workspace/` 为平台目标态目录骨架；现行九阶段流程（`@test-manager`）仍运行在 `qa-workspace/<项目>/<功能码>-<功能>/` 本地态结构上（产物 00-state ~ 05-tc-check、validate.sh 路径约定）。两套结构的映射与迁移方案待定（见 `DESIGN/工作空间目录结构.md` 复盘结论）。
