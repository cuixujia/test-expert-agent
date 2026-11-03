# workspace 运行时工作空间

依据 `DESIGN/工作空间目录结构.md`（AI 运行时工作空间目录结构）初始化。本目录是运行时骨架区：三个测试 agent（`@test-manager` 主流程、`@test-designer` 与 `@test-qa-expert` subagent）只读取输入、写入过程产物，不创建、不删除目录。

> 迁移说明：旧结构 `runtime_星云风险管理/file/PRD-第二稿/XZF-新增风险/session-log/`（含 bf-tp-tc.json 导出）已作废删除（git 历史可查）；现行契约为 `<bizFunctionId>/` 功能目录 + `<uuid>/` 会话目录 + `output/test-point|test-case/` 共享产物。

## 目录契约

```
workspace/runtime_<项目>/
└── file/
    └── <bizFunctionId>/                # 业务功能目录（一次流程一个业务功能，命名用业务功能编号；TP/TC 编号功能码由该编号直接派生）
        ├── prd-doc/                    # 【软链接或原件】PRD，只读；保留原文件名
        ├── prd.txt                     # PRD 文本快照（首次 S1 生成于本功能目录，锚点来源校验与摘录抄写的字符基准）
        ├── develop-docs/               # 【软链接】项目开发设计：fe-design/、be-design/（适用时 S6 必需，无界面功能由经理判定豁免）、db-design/（可选）
        ├── domain-knowledge/           # 【软链接】领域知识（S2 可选）
        ├── asset-library/              # 【软链接】逆向文档/功能知识/存量测试点/存量测试用例（可选）
        ├── code/                       # 【软链接】代码，只读
        ├── output/                     # 共享产物
        │   ├── test-point/test-point.md（采纳后补 test-point.json）
        │   └── test-case/test-case.md（采纳后补 test-case.json）
        └── <uuid>/                     # 会话目录（一次流程一个，骨架一并预置）
            ├── input/                  # 本次澄清/补充附件，只读
            ├── state.md                # 流程状态（PRD 指纹、CL 澄清、确认与派发会话记录）
            ├── scope.md                # 锚点底册（全流程唯一溯源底册）
            ├── prd-check.md            # S2 测试点资料质检报告
            ├── tp-check.md             # S4 测试点质检报告
            ├── design-check.md         # S6 测试用例资料质检报告
            └── tc-check.md             # S8 测试用例质检报告
```

## 取值与预置

| 层级 | 取值 | 说明 |
|---|---|---|
| `runtime_<项目>` | 建议按项目命名，如 `runtime_星云风险管理` | 应用运行时根，所有会话共用 |
| `<bizFunctionId>` | 业务功能编号（平台分配） | 功能目录名；TP/TC 编号功能码由该编号直接派生（无注册表文件） |
| `<uuid>` | 会话编号（含日期的 uuid 或 `<日期>-<序号>`） | 一次流程一个会话目录；流程重开经用户同意后改名归档（加 `-归档-<日期>` 后缀） |

骨架与输入材料由用户/平台程序预先准备（旧 `runtime_星云风险管理` 已作废删除，新骨架待按上表重建；PRD、前端/后端设计等原件以软链接或原件放入对应位置）。`prd.txt`、`scope.md`、`state.md` 与四份质检报告、`output/` 产物由 agent 流程生成，目录本身不建。

## 脚本调用（两个脚本按职责隔离）

```bash
# self-review-checklist/validate.sh —— 产出与状态侧（会话目录为入口）
# S3/S7 产物机验（产物自动取自功能目录 output/）
bash .opencode/skills/self-review-checklist/validate.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>" test-point
bash .opencode/skills/self-review-checklist/validate.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>" test-case
# 状态文件校验 / 产物 SHA-256
bash .opencode/skills/self-review-checklist/validate.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/state.md" state
bash .opencode/skills/self-review-checklist/validate.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>" hash test-point

# prd-quality-check/validate-prd.sh —— 需求与证据侧
# 快照生成（传功能目录，需源文件在 <bizFunctionId>/ 或 <bizFunctionId>/prd-doc/ 下）
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>" snapshot "<PRD 文件名.docx>"
# 底册机验 / 漏锚扫描（传会话目录 scope.md）
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/scope.md" scope
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/scope.md" scan
# 快照原文定位（传功能目录）
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>" find "<关键词>"
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>" line <行号>
bash .opencode/skills/prd-quality-check/validate-prd.sh "workspace/runtime_<项目>/file/<bizFunctionId>" cat
```

- 自动推导：会话目录取 `scope.md`；功能目录取 `prd.txt`；产物取 `output/test-point|test-case/`
- `all`（validate.sh）仅限人工调试，禁止用于阶段质检
