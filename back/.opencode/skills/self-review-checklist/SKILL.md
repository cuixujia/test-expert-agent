---
name: self-review-checklist
description: 测试点（S4）与测试用例（S8）质检清单、质检问题分级与处置方分类、覆盖对照表模板与 validate.sh 硬校验用法。质检阶段（测试质检专家执行）必须加载；必须运行 validate.sh，退出码非 0 时必须修复后重跑
---

# 质检清单（S4/S8，测试质检专家执行）

TP/TC 的定义与判据见 test-point-spec / test-case-spec，本 skill 只定义质检清单与校验用法，不复述定义。质检由测试质检专家（subagent）执行；修复归测试设计专家（subagent，S3/S7），派发与用户呈报归测试经理，复检由质检专家在原报告按轮次追加。

## TP 质检清单（S4，两关分工，逐项执行并留痕）

### 第一关 · 语义关（逐项，脚本无法替代）

1. **出处核对**：逐条 TP 按 test-point-spec「说得出出处」核对——锚点定位正确（摘录确实支撑该验证目标）；「PRD 没写、推出来」的按其三要素核对（来源已注明/挂最相关原文/不与明文矛盾）；两条都占不住的已按无依据处理。摘录与原文逐字一致不再人工核对，由 validate.sh 快照机验保证（见第二关）；用户澄清结论已登记（澄清登记规则见 test-manager 工作铁律 4）的，核对 TP 依据与澄清内容不矛盾
2. **切分线核对**：逐条 TP 按 test-point-spec「切得不多不少」核对（合并/拆分是否合规、三违规是否出现）；描述不清的已默认合并**且该模糊点已记入 prd-check.md 问题清单**，通过标准无法确定的已标记待澄清
3. **归组边界核对**：按 test-point-spec 收拢原则核对——没有把不同业务目标或 PRD 明文规定的不同处理硬合在一起，也没有把同一目标重复拆成多条 TP
4. **命名核对**：按 test-point-spec「命名」核对——「验证」+ 对象（PRD 原词直取）+ 结果方向；无具体预期表现、步骤、数据
5. **可判定核对**：逐条回答 test-point-spec「判得了对错」的问题「真执行了，看什么能分出过/不过？」；答不出的记入问题清单（Blocker，输入级）
6. **高风险判定**：非功能型 TP 的取舍依据（PRD 提及/高风险）明确合理
7. **覆盖反向核对**：以会话目录 scope.md 锚点清单为底册**逐锚点核对**；对已纳入范围的锚点，检查其下每条适用的明确要求都包含在对应 TP 的验证范围内，不能只因锚点有 TP 就判定该锚点覆盖完整；核对 S3 产出的覆盖对照表，范围外或不覆盖的锚点须补明显式原因（原因示例：流程图不可解析 / 非目标功能范围 / 用户确认不测）
8. **去重合并**：同一意图重复 TP 记入问题清单（产物级）；编号唯一由形式关机验
9. **名称一致性**：test-point.md 文件标题与正文引用的模块/功能名称与 scope.md 登记原文逐字一致（规则见 prd-quality-check）

### 第二关 · 形式关（validate.sh 必跑）

S4 校验传入会话目录并指定 `test-point` 模式（脚本读取功能目录 `output/test-point/test-point.md`，**禁止传 `all`**）：编号格式与唯一性（`TP-<功能码>-NNN`；功能码=平台 bizFunctionId，且必须等于所在功能目录名）、验证意图以「验证」开头、必填字段、TP 依据锚点在底册、底册锚点全覆盖、底册摘录 ≤40 字且逐字命中快照、TP 依据含底册摘录。

**脚本 PASS ≠ 质检通过；两关都过才可给出「通过」结论、test-point.md 方可定稿并发起「S4 质检结论 + S5 验收」合并确认。**

## TC 质检清单（S8，逐项执行并留痕）

1. **字段完备**：十字段（定义见 test-case-spec 字段规范）逐项非空；变更状态一律留空
2. **溯源完整**：关联 TP 均真实存在于 S5 验收通过的 test-point.md 清单；核对「TP ↔ TC 覆盖对照表」，未覆盖 TP 必须显式填写原因。常规 S6 资料检查通过后，所有已验收 TP 均须覆盖；仅用户明确批准的风险推进/不测决定可豁免，质检专家须核对 state.md 的 CL 或风险确认记录，不能仅凭非空原因放行
3. **比例提醒**：单个 TP 派生 TC 超过 10 条，须在质检记录表留痕说明原因（TP 过大或用例过碎），不硬禁
4. **步骤可执行**：按 test-case-spec 质量标准核对——入口具体、动词开头、无歧义词，第三方可照做
5. **预期可判定**：按 test-case-spec 质量标准核对——有具体值/文案/状态，可直接判 pass/fail
6. **单一目的**：一条用例一个验证目的，即一个 pass/fail 结论（判据见 test-case-spec 质量标准）；发现混合意图的记入问题清单（产物级，拆分修复）
7. **领域复核**：对照 test-analysis-methods 三大领域专项检查单，补齐遗漏（银行重点：金额精度/幂等/权限；接口重点：异常码/超时重试）
8. **名称一致性**：test-case.md 文件标题与正文引用的模块/功能名称与 scope.md 登记原文逐字一致
9. **形式关**：运行 validate.sh，S8 校验传入会话目录并指定 `test-case` 模式（脚本读取功能目录 `output/test-case/test-case.md`，**禁止传 `all`**）；全部 PASS 且 TP 语义关已经过，方可给出「通过」结论、test-case.md 定稿并发起「S8 质检结论 + S9 评审」合并确认

## 质检问题分级与处置方（S4/S8 报告必标）

问题清单逐条标注两项：

| 标注 | 取值 | 判定基准 |
|---|---|---|
| 级别 | Blocker / Major | Blocker = TP/TC 无依据或无法判定通过与否；Major = 可修的形式与粒度问题，或未决问题可能改变范围、拆分或验收结果（S4/S8 按本表就地判定；通用分级基准见 prd-quality-check，面向 S2/S6） |
| 处置方 | **产物级** / **输入·基线级** | 产物级 = S3/S7 可修（切分、命名、字段、步骤、预期等），走修复循环；输入·基线级 = PRD 歧义、材料缺口、TP 基线错误——测试经理须**立即暂停修复循环**呈报用户处置，禁止在循环内硬编硬造 |

> 指针说明：本清单中的「见 prd-quality-check / tdd-quality-check」（分级基准、名称一致、摘录机验降级、S6 风险处置）只标注规则来源——S4/S8 质检按本清单与派发单所指材料就地执行，不要求加载这两个 skill（两者面向 S2/S6）。「澄清登记规则见 test-manager 工作铁律 4」同理，所需澄清内容已由派发单内嵌。

## 质检闭环（问题清单 → 修复 → 复检）

- 质检专家产出问题清单（tp-check.md / tc-check.md，位于会话目录）；修复归生成者（S3/S7）
- 复检按轮次在原质检报告内追加，不覆盖此前记录；每轮保留问题编号、发现、处置、复核结论与未解决项
- S3/S7 每次修复在 test-point.md / test-case.md 文件尾部「质检记录」表中留痕：

```markdown
## 质检记录
| 轮次 | 检查项 | 发现 | 修复动作 | 复核结果 |
|---|---|---|---|---|
```

- 禁止只报告不修复、只修复不复核；禁止产物级问题未经修复直接复检通过

## 覆盖对照表模板

TP 覆盖对照表与 TC 覆盖对照表的列结构分别见 test-point-spec / test-case-spec 的清单模板节。

## validate.sh 用法（必跑）

机械校验分层执行：设计 subagent 交稿前运行对应模式并返回退出码与最终产物 SHA-256；测试经理收回时比对 SHA-256，只有文件变更、指纹不一致或缺少有效校验记录时才补跑；质检 subagent 在 S4/S8 对最终文件运行正式校验并把退出码写入报告。经理的指纹核对不替代质检专家的正式校验，文件未变化时不得无故重复跑同一轮机械校验。

```bash
# S4：测试点质检（仓库根目录执行，路径含空格必须加引号；会话目录为入口，产物在功能目录 output/，禁止传 all）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>" test-point

# S8：用例质检（同上；自动推导会话目录 scope.md、功能目录 prd.txt 与 output/test-case/）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>" test-case

# S1：底册校验（无 test-point 时也可机验：scope.md 锚点清单 + 摘录逐字命中快照）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/scope.md" scope

# state.md 校验（登记项固定词汇表且唯一/确认记录格式/CL 编号唯一/PRD 指纹格式）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/state.md" state

# 摘录程序化提取（先自验命中快照再输出到 stdout，供底册/依据列填充；禁止模型手抄）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>/<uuid>/scope.md" pull "<锚点>"

# 快照生成（textutil + 引号归一 + 输出源文件 md5；传功能目录，落 <功能目录>/prd.txt；只读，已存在即拒绝重建）
bash ".opencode/skills/self-review-checklist/validate.sh" "workspace/runtime_<项目>/file/<bizFunctionId>" snapshot "<PRD 文件名.docx>"
```

- 目录推导：会话目录（`<uuid>`）内取 `scope.md`；功能目录（上一级）取 `prd.txt` 快照与 `prd-doc/` 原件；产物取功能目录 `output/test-point/test-point.md` 与 `output/test-case/test-case.md`
- S4 传 `test-point` 模式（编号格式与唯一性、scope.md 锚点底册核对、摘录逐字机验）；S8 传 `test-case` 模式（含 TC 字段、TC→TP 引用、TP 全覆盖）；`all` 仅限人工调试，禁止用于阶段质检
- 校验项：锚点清单底册（scope.md 锚点清单存在、TP 依据锚点全部在底册、底册锚点全部出现在覆盖对照表）、test-point/test-case 编号格式与唯一性（`TP-<功能码>-NNN`；功能码=平台 bizFunctionId，且编号功能码段必须等于功能目录名）、验证意图以「验证」开头、必填字段非空、TC→TP 引用完整性、覆盖对照表存在性与未覆盖项原因声明、摘录逐字机验
- **TP 全覆盖豁免**：validate.sh 只检查未覆盖原因是否填写，不判断用户是否批准。S8 语义质检还须核对该原因对应的 state.md 澄清/风险确认；前端或后端等必需资料问题未解决时不得以覆盖豁免代替资料补齐。没有有效用户决定的未覆盖 TP 不得质检通过
- 摘录逐字机验：scope.md 底册原文摘录 ≤40 字且逐字命中功能目录 `prd.txt` 快照（比对前做空白规范化，含全角空格）；TP 依据必须包含对应锚点的底册摘录；快照缺失报 FAIL；scope.md 标注「快照机验：跳过（原因）」时输出 WARN 并跳过（降级声明，规则见 prd-quality-check 锚点规则 9）
- 脚本兼容性注意：macOS awk 的 `length()` 按字节计数，摘录长度校验必须用 `wc -m`（LC_ALL=en_US.UTF-8）；且在 LC_ALL=UTF-8 下对纯中文串的 `==` 比较会误判真——validate.sh 的 awk 一律走 C locale 字节语义（不设 LC_ALL），中文相等判断用正则或 `index()`
- 判读：退出码 0 = 通过；非 0 = 质检不通过，**必须修复后重跑**，禁止带 FAIL 定稿
