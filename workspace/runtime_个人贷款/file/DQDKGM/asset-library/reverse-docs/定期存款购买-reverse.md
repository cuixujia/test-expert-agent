# 定期存款购买

## 📋 基本信息

- **功能代码**: `FUN202610162110835962088218625`
- **创建时间**: 2026-10-16 18:55:30
- **更新时间**: 2026-10-16 18:55:30

## 📖 功能描述

支持个人客户通过手机银行在线办理定期存款购买业务，包括普通定期存款和定期定投签约两种模式，实现资金从活期账户到定期存款的转化。客户登录手机银行 APP，在首页或理财频道点击存款入口，进入定期存款购买页面。参与角色包括个人客户、客户经理和系统。前置条件为客户已登录并完成身份认证、存在正常活期结算账户、存在在售定期存款产品。完成标准为定期存款合约成功开立、交易流水记录完成、客户查看到交易详情。业务范围涵盖普通定期存款一次性购买和定期定投签约两种业务模式，支持本人账户和亲情账户两种场景。用户可见失败结果包括交易要素校验失败、核心系统处理失败、通讯超时或可疑状态。

## 📦 业务对象

| 序号 | 业务对象 | 定义 | 关键字段 |
|------|----------|------|----------|
| 1 | 存款产品 | 银行向客户提供的各类定期存款产品，包括普通定期、百盈存款、养老存款、结构性存款等，包含利率、存期、起存金额等核心要素 | 产品代码、产品名称、年利率、存期、起存金额、续存方式、产品有效期、上架状态 |
| 2 | 转出账户 | 客户用于购买定期存款的付款账户，通常为活期储蓄账户或活期结算账户（借记卡、活期存折），需验证账户状态和余额充足性 | 账号、账户类型、账户余额、账户状态、开户网点、介质号 |
| 3 | 定期存款合约 | 客户购买定期存款后形成的存款法律凭证，记录存款金额、存期、利率、到期日等核心要素，是存款关系的正式确认 | 合约编号、存款金额、存期、年利率、起息日、到期日、存入账号、续存方式 |
| 4 | 客户信息 | 购买定期存款的客户主体身份信息，支持本人账户和亲情账户两种场景，亲情账户需验证监护关系 | 客户号、姓名、证件类型、证件号码、客户等级、风险等级 |
| 5 | 亲情账户 | 子女为父母代为购买的托管账户场景，支持代理人信息和推荐人登记，需验证未下挂卡列表中的卡号与客户号匹配关系 | 亲情账号、监护人客户号、被监护人姓名、关系类型、代理人信息 |
| 6 | 定投协议 | 客户与银行签订的定期定额投资协议，约定每期扣款金额、扣款日期、存期等要素，实现自动化的定期存款投资 | 协议编号、定投金额、扣款日、存期、扣款账户、协议状态、起止日期 |
| 7 | 交易流水 | 记录定期存款购买过程中的每一笔交易操作，包括交易时间、交易类型、交易金额、交易状态、核心返回码等追踪信息 | 流水号、指令流水号、交易时间、交易类型、交易金额、交易状态、主机返回码 |
| 8 | 客户经理 | 为客户提供理财服务的专属经理，客户购买存款时可选择关联经理，用于业绩归属和后续服务跟踪 | 经理工号、经理姓名、所属支行、联系方式、业绩归属机构 |
| 9 | 利率配置 | 银行配置的各类存款产品利率信息，包括基准利率、上浮比例、执行利率，支持多币种、多期限和分行地区差异化 | 利率代码、基准利率、上浮比例、执行利率、币种、期限、适用地区、生效日期 |
| 10 | 货架配置 | 存款产品在首页的展示配置，包含模块 ID、标签页、产品排序、展示开关、白名单控制等 | 模块 ID、标签页、展示开关、产品列表、白名单标识、排序号 |
| 11 | 抽奖活动 | 定期存款购买成功后可能参与的营销活动，记录客户的抽奖次数和活动状态 | 活动编号、抽奖次数、可抽奖标识、活动状态 |

## 📊 流程图

```mermaid
flowchart TD
    N_Start(["客户进入定期存款购买页面"]) --> SG_Phase1

    subgraph SG_Phase1["阶段一：页面加载与产品展示"]
        direction TB
        N_PageLoad["系统加载购买页面"] --> N_QueryShelf["查询存款产品货架配置"]
        N_QueryShelf --> N_FilterProducts["过滤可售产品并展示"]
        N_FilterProducts --> N_ShowRates["展示产品利率和起存金额"]
        N_ShowRates --> N_Phase1End["页面就绪：展示普通定期和定投签约选项"]
    end

    SG_Phase1 --> N_Phase1EndOuter["页面加载完成"]

    N_Phase1EndOuter --> N_ModeSelect{"客户选择业务模式"}

    N_ModeSelect -->|普通定期 | SG_Phase2
    N_ModeSelect -->|定期定投 | SG_Phase6

    subgraph SG_Phase2["阶段二：选择转出账户"]
        direction TB
        N_SelectAccount["客户点击转出账户选择控件"] --> N_QueryAccounts["系统查询客户可用账户列表"]
        N_QueryAccounts --> N_ValidateAccounts["验证账户状态和可用性"]
        N_ValidateAccounts --> N_ShowBalance["展示账户余额和尾号"]
        N_ShowBalance --> N_ConfirmAccount["客户确认选择转出账户"]
    end

    SG_Phase2 --> N_AccountSelected["转出账户已选择"]

    N_AccountSelected --> SG_Phase3

    subgraph SG_Phase3["阶段三：录入购买金额"]
        direction TB
        N_InputAmount["客户输入购买金额"] --> N_CheckMinAmount["系统校验起存金额要求"]
        N_CheckMinAmount --> N_CheckBalance["验证账户余额充足性"]
        N_CheckBalance --> N_CalcYield["实时计算并展示预期收益"]
        N_CalcYield --> N_AmountValidated["金额校验通过"]
    end

    SG_Phase3 --> N_AmountValidatedOuter["金额已确认"]

    N_AmountValidatedOuter --> SG_Phase4

    subgraph SG_Phase4["阶段四：确认购买提交"]
        direction TB
        N_CheckVideo["客户勾选视频回溯选项"] --> N_SelectManager["客户选择客户经理（可选）"]
        N_SelectManager --> N_ReadTips["客户阅读温馨提示"]
        N_ReadTips --> N_ClickConfirm["客户点击确认按钮提交交易"]
        N_ClickConfirm --> N_FinalValidate["系统最终校验所有交易要素"]
        N_FinalValidate --> N_CallCore["调用核心系统执行活期转定期"]
        N_CallCore --> N_CoreProcess{"核心处理结果"}
        N_CoreProcess -->|20-成功 | N_Success["交易成功：生成存款合约"]
        N_CoreProcess -->|10-可疑 | N_Suspect["通讯可疑：记录流水后告知待确认"]
        N_CoreProcess -->|30-失败 | N_Fail["交易失败：记录流水并返回错误"]
    end

    SG_Phase4 --> N_TransactionResult{"交易结果"}

    N_TransactionResult -->|成功 | SG_Phase5
    N_TransactionResult -->|可疑 | N_SuspectEnd["告知客户交易状态待确认<br/>提供后续查询入口"]
    N_TransactionResult -->|失败 | N_FailEnd["展示失败原因<br/>提供重试入口"]

    subgraph SG_Phase5["阶段五：跳转结果页"]
        direction TB
        N_UpdateCache["更新会话缓存账户列表"] --> N_RegisterReferee["登记推荐人信息（可选）"]
        N_RegisterReferee --> N_TriggerLottery["触发抽奖活动（如适用）"]
        N_TriggerLottery --> N_JumpResult["跳转到结果页面"]
        N_JumpResult --> N_ShowDetail["展示交易详情：流水号、账号、金额、日期"]
        N_ShowDetail --> N_ProvideNav["提供返回/继续浏览入口"]
    end

    SG_Phase5 --> N_EndSuccess(["客户查看到购买成功结果"])

    subgraph SG_Phase6["阶段六：定投签约流程"]
        direction TB
        N_SwitchMode["客户切换到定期定投签约选项卡"] --> N_SelectPeriod["客户选择定投期限和扣款日"]
        N_SelectPeriod --> N_InputFixedAmount["客户输入每期定投金额"]
        N_InputFixedAmount --> N_CheckFixedMin["系统校验起投金额限制"]
        N_CheckFixedMin --> N_CreateAgreement["创建预约转账协议"]
        N_CreateAgreement --> N_SignContract["核心系统执行定投签约"]
        N_SignContract --> N_SignResult{"签约结果"}
        N_SignResult -->|成功 | N_SignSuccess["生成协议编号和定投计划"]
        N_SignResult -->|失败 | N_SignFail["签约失败并提示错误原因"]
    end

    SG_Phase6 --> N_SignOutcome{"签约结果"}

    N_SignOutcome -->|成功 | N_EndSignSuccess(["客户查看到定投签约成功结果"])
    N_SignOutcome -->|失败 | N_EndSignFail["展示签约失败原因<br/>提供重新签约入口"]

    style N_Start fill:#90EE90,stroke:#333,stroke-width:2px
    style N_EndSuccess fill:#FFB6C1,stroke:#333,stroke-width:2px
    style N_EndSignSuccess fill:#FFB6C1,stroke:#333,stroke-width:2px
    style N_SuspectEnd fill:#FFD700,stroke:#333,stroke-width:2px
    style N_FailEnd fill:#FF6B6B,stroke:#333,stroke-width:2px
    style N_EndSignFail fill:#FF6B6B,stroke:#333,stroke-width:2px
```

## 🔄 业务流程

阶段一：进入购买页面与产品展示。客户登录手机银行 APP 后，在首页或理财频道点击存款入口，进入存款产品中心页面。客户点击定期存款产品卡片或定期存款导航入口，系统进入定期存款购买页面。页面加载时，系统根据模块 ID 查询存款首页货架配置，获取展示的存款产品列表、产品排序和推荐标识。系统调用财富服务查询受控存款产品和百盈存款产品，过滤出当前客户可购买的产品范围。系统根据产品代码和存期查询执行利率，包括基准利率、上浮比例和分行地区差异化利率。页面展示存款类型、存款年利率、续存方式、起存金额等产品信息。系统同时查询公共参数配置，获取定期定投开关、首页开关等配置项，控制页面元素的显示与隐藏。

阶段二：选择转出账户。客户点击转出账户选择控件，系统弹出账户选择弹窗，展示客户名下所有可用的活期结算账户。账户列表显示每张卡的卡号（脱敏）、账户类型、账户余额、账户状态。系统验证选中账户的状态是否正常、是否为受控账户、余额是否足够，对不可用账户进行灰化或提示不可用原因。客户点击确认选择某个账户后，页面回显该账户的尾号和当前余额，作为购买资金的扣款账户。付款卡号必须存在于当前登录用户的缓存卡列表中，否则系统拒绝交易并提示账号校验失败。

阶段三：录入购买金额。客户在金额输入框中输入购买金额，可以选择点击"全部买入"按钮快速填入账户全部可用余额。系统实时校验输入金额是否满足产品规定的最低起存金额要求，不满足时显示提示语阻止提交。系统检查输入金额是否超过转出账户可用余额，超额时阻止提交并提示余额不足。系统根据存款金额、存期和年利率实时计算到期预期收益，在页面底部展示预期收益，帮助客户决策。预期收益按单利计算，公式为：收益 = 本金×年利率×存期/365，不考虑复利因素，实际收益以到期结算为准。

阶段四：确认购买提交。客户勾选视频回溯选项，系统记录客户同意进行双录，满足监管要求的录音录像规定。客户阅读页面下方的温馨提示，了解起存金额、利率标准、存款保险保障等重要信息。客户可选择关联客户经理（可选操作），用于业绩归属和后续服务。客户点击底部"确认"按钮，系统再次校验所有交易要素完整性，包括产品、账户、金额、利率、存期等必填项。当存款类型为定期时，存期参数不能为空。系统调用活期转定期存款提交接口，传递产品代码、存期、转出账号、购买金额、账户类型等交易要素。核心系统执行活期账户扣款和定期账户开户的复合交易，生成存款合约号，登记存款账户信息。系统调用介质凭证类型查询和客户印鉴检查接口，验证客户身份和交易凭证的合法性。核心系统返回交易结果分为三类状态：状态 20（成功）直接返回成功结果；状态 10（可疑）记录流水后返回可疑状态；状态 30（失败）记录流水后抛出异常终止流程。

阶段五：处理交易结果并跳转结果页。定期账户开立成功后，系统同步更新会话缓存中的账户列表，确保后续查询能立即看到新开立的账户。系统尝试登记推荐人信息（可选操作），即使调用网关失败也仅记录日志不影响主交易流程的成功完成。系统触发抽奖活动（如适用），每个客户在活动期间最多获得配置的抽奖次数上限，已达上限时不再增加抽奖机会但存款交易仍可成功完成。购买成功后，系统自动跳转到定期存款结果页面。结果页使用成功状态组件，展示绿色对勾图标和"购买成功"文字，告知客户交易已完成。页面展示流水号、购买账号（脱敏）、购买金额、购买日期等关键交易信息，供客户核对确认。页面提供返回按钮和导航链接，客户可以选择返回存款首页、查看持仓详情或继续浏览其他产品。

分支流程：定期定投签约模式下，客户在购买页面点击顶部"定期定投签约"选项卡，页面切换到定投签约模式。客户通过省市区选择器选择定投扣款的地区和期限，确定每月/每期的扣款日期和存期。客户输入每期定投金额，系统校验起投金额限制，并展示预期收益测算。系统调用预约转账建立接口，创建预约转账协议，约定扣款账户、扣款日期、扣款金额、起止日期等要素。核心系统执行预约转账签约交易，生成协议编号，登记定投计划。亲情账户场景下，当客户选择为亲情账户购买定期存款时，系统需验证卡号存在于未下挂卡列表中且能匹配到对应的客户号。子女可以为父母代为购买定期存款，支持代理人信息和推荐人登记。交易异常处理包括核心通讯可疑时告知客户交易状态待确认、交易失败时展示具体失败原因并提供重试入口、推荐人登记失败仅记录日志不影响主交易、抽奖机会已达上限时不再增加但不影响交易成功。
## 📏 业务规则

- **必填字段校验**【校验规则】: 转出方介质号、转入方介质号、转账金额、周期代码、预约周期、起止日期、密码为必填项
- **金额格式校验**【校验规则】: 购买金额必须为正数且最多保留 6 位小数，格式为^[0-9]*\.?[0-9]{0,6}$
- **卡号有效性校验**【校验规则】: 付款卡号必须存在于当前登录用户的缓存卡列表中
- **存期必填规则**【校验规则】: 当存款类型为定期（非 1）时，存期参数 savePeriod 不能为空
- **亲情账户校验**【校验规则】: 当 registerFlag 为 1 时，需验证卡号存在于未下挂卡列表中且能匹配到对应的客户号
- **起存金额校验**【校验规则】: 客户输入的购买金额必须大于等于产品规定的最低起存金额
- **账户余额校验**【校验规则】: 购买金额不得超过转出账户的可用余额
- **账户状态校验**【校验规则】: 转出账户必须为正常状态，冻结、止付、销户等异常状态的账户不能用于购买
- **产品可售性校验**【校验规则】: 只能购买当前在售的存款产品，产品必须在有效期内且上架状态为 0
- **客户身份校验**【校验规则】: 购买人必须为账户持有人或经授权的代理人，亲情账户场景需验证监护关系
- **展示开关控制**【业务约束】: 当全局配置中 showFlag 为 OFF 时，无论其他配置如何，均返回空列表，不展示该货架
- **产品类型限制**【业务约束】: 仅允许展示产品大类为 5（普通存款）或 8（结构性存款）的产品，其他类型产品自动过滤
- **产品有效期校验**【业务约束】: 产品必须在有效期内（开始日期<=当前日期<=结束日期）且上架状态为 0 才会被查询返回
- **白名单控制**【业务约束】: 支持通过 custSaleCtrlFlag 字段控制产品是否为白名单专属，非白名单客户不可见白名单产品
- **存期固定约束**【业务约束】: 定期存款的存期为固定档次（如 3 个月、6 个月、1 年、2 年、3 年、5 年），客户不能自定义存期
- **账户类型约束**【业务约束】: 只能使用活期结算账户（借记卡、活期存折）作为转出账户购买定期存款，信用卡不能用于购买
- **交易时间约束**【业务约束】: 定期存款购买交易支持 7×24 小时线上办理，部分特殊产品可能有限制
- **限购数量约束**【业务约束】: 同一客户对同一存款产品的持有份额不能超过该产品规定的单人最高限额
- **撤单约束**【业务约束】: 定期存款购买成功后不能撤单，提前支取按活期利率计息，损失定期利息收益
- **续存方式约束**【业务约束】: 到期续存方式只能选择自动转存或到期支取，转存时按转存日挂牌利率执行
- **定投互斥约束**【业务约束】: 普通定期存款和定期定投签约两种模式互斥，客户一次只能选择其中一种模式办理
- **双录要求**【业务约束】: 根据监管要求，大额存款购买需要进行录音录像，客户必须勾选同意视频回溯才能继续交易
- **预期收益计算**【计算规则】: 收益 = 本金×年利率×存期/365（单利计算，存期不足一年按比例折算）
- **利率浮动计算**【计算规则】: 执行利率 = 基准利率×(1+ 上浮比例)，不同分行地区可能有差异化的上浮政策
- **利息计算规则**【计算规则】: 定期存款利息 = 本金×年利率×存期（年），算头不算尾，实际收益以到期结算为准
- **抽奖次数限制**【计算规则】: 每个客户在活动期间最多获得配置的抽奖次数上限，已达上限时不再累加但不影响交易成功
- **交易状态处理**【流程规则】: 核心返回状态分为三类：20-成功直接返回；10-可疑（通讯失败）记录流水后返回可疑状态；30-失败记录流水后抛出异常终止流程
- **会话缓存一致性**【流程规则】: 定期账户开立成功后必须同步更新会话缓存中的账户列表，确保后续查询能立即看到新开立的账户
- **推荐人登记容错**【流程规则】: 推荐人信息录入为可选操作，即使调用网关失败也仅记录日志不影响主交易流程
- **交易顺序约束**【流程规则】: 必须先选择产品和转出账户、录入金额后才能点击确认提交，前置条件不满足时按钮置灰
- **结果页跳转**【流程规则】: 购买成功后必须跳转到结果页展示交易详情，失败时显示错误原因并提供重试入口
- **分级授权**【流程规则】: 超过一定金额的存款购买可能需要更高级别的授权，系统根据金额自动判断是否需要人工审核
- **存款保险保障**【通用规则】: 根据《存款保险条例》，存款本金和利息受存款保险保障，最高偿付限额为人民币 50 万元
- **信息披露**【通用规则】: 银行需在显著位置公示存款产品的利率、期限、起存金额等关键信息，保障客户知情权
- **客户知情权**【通用规则】: 客户有权了解存款产品的详细信息，包括利率、存期、提前支取规则、费用标准等
- **隐私保护**【通用规则】: 客户的账户信息、交易记录等敏感数据需进行脱敏展示和加密传输，保护客户隐私安全
## 🌐 业务UI

其他金融服务 → 养老专区 → 财富阁 → 定期存款购买
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-pensionZone-wealth-pensionZone-termDeposit-termDepositBuy.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=1ac27aacbd4db1dfa05f028a78807dc84fdc2c815916bd5ccb5803a0dfd979c6

其他金融服务 → 养老专区 → 财富阁 → 定期存款购买扫码页
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-pensionZone-wealth-pensionZone-depositCenter-allDepositBuyScan.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=b1ddd05d37bbeccaa7b76d44abf8be8a5c4f1dd87bdd4b0332809742bf8000c5

存款服务 → 定期存款 → 定期存款购买
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-termDeposit-termDepositBuy.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=91bd6a42b4d23de64ed89d6590a58ae280f458f771441f04f51d97e740359c2f

存款服务 → 定期存款 → 定期存款购买 → 定期存款
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-termDeposit-termDepositBuy-termDeposit-termDepositResult.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=a2f1c1d54e7b494eb40843584a249c66aa2d918f3eff453adc54861e9621fe1d

存款服务 → 定期存款 → 定期存款购买
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-termDeposit-termDepositBuyOfSh.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=4467e303a063c3397a578dae84b894077c68f99d2da2bbf41f1c95f14aa01ba1

存款服务 → 定期存款 → 定期存款购买
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-termDeposit-termDepositBuyScan.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=66acb95ce1b56ace679700af650b12fd72f6ad72c1f7be2fac7050f4af6e17d3

存款服务 → 定期存款 → 定期存款
http://195.255.101.200:9000/reverse-engineering-doc/SUBSYS_PMBWEB/screenshot/SUBSYS_PMBWEB-termDeposit-termDepositOfSh.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=root%2F20261029%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261029T075451Z&X-Amz-Expires=86400&X-Amz-SignedHeaders=host&X-Amz-Signature=95fb9ecdaa96841a1fb4924a56d0c8b504f84ecc1aca2f322b6ae5e612df25cc



## 🔗 调用链路

#### 其他金融服务 → 养老专区 → 财富阁 → 定期存款购买

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/pensionZone/termDeposit/termDepositBuy "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98470["&#91SUBSYS_PMB_APP&#93 🎯 新公共参数表查询 <br/> /pubServer/pmbPubArgQuery"]
  class 98470 apiRoot;
  93756["&#91SUBSYS_PMB_APP&#93 🎯 存款首页货架信息查询 <br/> /depositShelf/depositProdShelfSearch"]
  class 93756 apiRoot;
  129063["&#91SUBSYS_PERBANK_WEALTH&#93 存款货架产品查询 <br/> /depositProdShelf/depositProdShelfSearch"]
  class 129063 ok;
  98142["&#91SUBSYS_PMB_APP&#93 🎯 受控存款产品查询 <br/> /termDeposit/ctrlProductQuery"]
  class 98142 apiRoot;
  129644["&#91SUBSYS_PERBANK_WEALTH&#93 受控存款产品查询 <br/> /deposit/ctrlProductQuery"]
  class 129644 ok;
  95712["&#91SUBSYS_PMB_APP&#93 🎯 百盈存款产品列表查询 <br/> /hundredProfitDeposit/hundredProfitDepositQueryProd"]
  class 95712 apiRoot;
  129619["&#91SUBSYS_PERBANK_WEALTH&#93 存款产品查询 <br/> /deposit/depositProductsQuery"]
  class 129619 ok;
  95728["&#91SUBSYS_PMB_APP&#93 🎯 查询利率 <br/> /hundredProfitDeposit/queryRate"]
  class 95728 apiRoot;
  129632["&#91SUBSYS_PERBANK_WEALTH&#93 查询网银利率 <br/> /deposit/queryRate"]
  class 129632 ok;
  95744["&#91SUBSYS_PMB_APP&#93 🎯 亲情账户存款购买 <br/> /hundredProfitDeposit/hundredProfitDepositPayForKids"]
  class 95744 apiRoot;
  128961["&#91SUBSYS_PERBANK_WEALTH&#93 亲情账户存款购买 <br/> /hundredProfitDeposit/currentToTermSubForKids"]
  class 128961 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  128961_unmatched_1["⚠️ com.hzbank.trans.pbty.commo..."]
  class 128961_unmatched_1 unmatched;
  98124["&#91SUBSYS_PMB_APP&#93 🎯 活期转定期存款提交 <br/> /termDeposit/currentToTermSub"]
  class 98124 apiRoot;
  129617["&#91SUBSYS_PERBANK_WEALTH&#93 定期存款提交 <br/> /deposit/currentToTermSub"]
  class 129617 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  129617_unmatched_1["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_1 unmatched;
  129617_unmatched_2["⚠️ com.hzbank.trans.pbty.commo..."]
  class 129617_unmatched_2 unmatched;
  129617_unmatched_3["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_3 unmatched;
  94420["&#91SUBSYS_PMB_APP&#93 🎯 预约转账建立 <br/> /transfer/transferEstablishment"]
  class 94420 apiRoot;
  94734["&#91SUBSYS_PERBANK_TRANSFER&#93 预约转账建立 <br/> /transferOrderQuery/transferEstablishment"]
  class 94734 ok;
  128201["&#91SUBSYS_DORE_ADPS&#93 预约转账签约 <br/> /agdp/IDIB05/AAGDP31500/v1.0.0"]
  class 128201 ok;
  130239["&#91SUBSYS_DORE_BIDP&#93 单介质账户路由查询 <br/> /idib/IDIB/BIDIB72317/v1.0.0"]
  class 130239 ok;
  130239_unmatched_0["⚠️ SVCIDIB030"]
  class 130239_unmatched_0 unmatched;
  126148["&#91SUBSYS_DORE_BPDP&#93 预约转账签约（个人） <br/> /pdpp/PDPP/BPDPP31200/v1.0.0"]
  class 126148 ok;
  126148_unmatched_0["⚠️ SVCPDPP001"]
  class 126148_unmatched_0 unmatched;
  126148_unmatched_1["⚠️ SVCPDPP005"]
  class 126148_unmatched_1 unmatched;
  126148_unmatched_2["⚠️ SVCPDPP009"]
  class 126148_unmatched_2 unmatched;
  129907["&#91SUBSYS_DORE_BCDP&#93 预约转账签约（对公） <br/> /cdcp/CDCP/BCDCP31200/v1.0.0"]
  class 129907 ok;
  129907_unmatched_0["⚠️ SVCCDCP001"]
  class 129907_unmatched_0 unmatched;
  129907_unmatched_1["⚠️ SVCCDCP005"]
  class 129907_unmatched_1 unmatched;
  129907_unmatched_2["⚠️ SVCCDCP009"]
  class 129907_unmatched_2 unmatched;

  menuRoot -->|菜单第 1 个 API: POST| 98470;
  menuRoot -->|菜单第 2 个 API: POST| 93756;
  menuRoot -->|菜单第 3 个 API: POST| 98142;
  menuRoot -->|菜单第 4 个 API: POST| 95712;
  menuRoot -->|菜单第 5 个 API: POST| 95728;
  menuRoot -->|菜单第 6 个 API: POST| 95744;
  menuRoot -->|菜单第 7 个 API: POST| 98124;
  menuRoot -->|菜单第 8 个 API: POST| 94420;
  93756 -->|feign| 129063;
  98142 -->|feign| 129644;
  95712 -->|feign| 129619;
  95728 -->|feign| 129632;
  95744 -->|feign| 128961;
  128961 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  128961 -->|sdk| 128961_unmatched_1;
  98124 -->|feign| 129617;
  129617 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  129617 -->|unknown| 129617_unmatched_1;
  129617 -->|sdk| 129617_unmatched_2;
  129617 -->|unknown| 129617_unmatched_3;
  94420 -->|unknown| 94734;
  94734 -->|sdk| 128201;
  128201 -->|component| 130239;
  130239 -->|component| 130239_unmatched_0;
  128201 -->|component| 126148;
  126148 -->|component| 126148_unmatched_0;
  126148 -->|component| 126148_unmatched_1;
  126148 -->|component| 126148_unmatched_2;
  128201 -->|component| 129907;
  129907 -->|component| 129907_unmatched_0;
  129907 -->|component| 129907_unmatched_1;
  129907 -->|component| 129907_unmatched_2;
```


#### 其他金融服务 → 养老专区 → 财富阁 → 定期存款购买扫码页

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/pensionZone/depositCenter/allDepositBuyScan "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98379["&#91SUBSYS_PMB_APP&#93 🎯 查询公共参数展示信息 <br/> /pubServer/queryPubParamShowMsgs"]
  class 98379 apiRoot;
  98124["&#91SUBSYS_PMB_APP&#93 🎯 活期转定期存款提交 <br/> /termDeposit/currentToTermSub"]
  class 98124 apiRoot;
  129617["&#91SUBSYS_PERBANK_WEALTH&#93 定期存款提交 <br/> /deposit/currentToTermSub"]
  class 129617 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  129617_unmatched_1["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_1 unmatched;
  129617_unmatched_2["⚠️ com.hzbank.trans.pbty.commo..."]
  class 129617_unmatched_2 unmatched;
  129617_unmatched_3["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_3 unmatched;
  95719["&#91SUBSYS_PMB_APP&#93 🎯 百盈存款购买 <br/> /hundredProfitDeposit/hundredProfitDepositPay"]
  class 95719 apiRoot;
  95719_unmatched_0["⚠️ SJAPHF03"]
  class 95719_unmatched_0 unmatched;

  menuRoot -->|菜单第 1 个 API: POST| 98379;
  menuRoot -->|菜单第 2 个 API: POST| 98124;
  menuRoot -->|菜单第 3 个 API: POST| 95719;
  98124 -->|feign| 129617;
  129617 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  129617 -->|unknown| 129617_unmatched_1;
  129617 -->|sdk| 129617_unmatched_2;
  129617 -->|unknown| 129617_unmatched_3;
  95719 -->|feign| 95719_unmatched_0;
```


#### 存款服务 → 定期存款 → 定期存款购买

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/termDeposit/termDepositBuy "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98470["&#91SUBSYS_PMB_APP&#93 🎯 新公共参数表查询 <br/> /pubServer/pmbPubArgQuery"]
  class 98470 apiRoot;
  93756["&#91SUBSYS_PMB_APP&#93 🎯 存款首页货架信息查询 <br/> /depositShelf/depositProdShelfSearch"]
  class 93756 apiRoot;
  129063["&#91SUBSYS_PERBANK_WEALTH&#93 存款货架产品查询 <br/> /depositProdShelf/depositProdShelfSearch"]
  class 129063 ok;
  98142["&#91SUBSYS_PMB_APP&#93 🎯 受控存款产品查询 <br/> /termDeposit/ctrlProductQuery"]
  class 98142 apiRoot;
  129644["&#91SUBSYS_PERBANK_WEALTH&#93 受控存款产品查询 <br/> /deposit/ctrlProductQuery"]
  class 129644 ok;
  95712["&#91SUBSYS_PMB_APP&#93 🎯 百盈存款产品列表查询 <br/> /hundredProfitDeposit/hundredProfitDepositQueryProd"]
  class 95712 apiRoot;
  129619["&#91SUBSYS_PERBANK_WEALTH&#93 存款产品查询 <br/> /deposit/depositProductsQuery"]
  class 129619 ok;
  95728["&#91SUBSYS_PMB_APP&#93 🎯 查询利率 <br/> /hundredProfitDeposit/queryRate"]
  class 95728 apiRoot;
  129632["&#91SUBSYS_PERBANK_WEALTH&#93 查询网银利率 <br/> /deposit/queryRate"]
  class 129632 ok;
  95744["&#91SUBSYS_PMB_APP&#93 🎯 亲情账户存款购买 <br/> /hundredProfitDeposit/hundredProfitDepositPayForKids"]
  class 95744 apiRoot;
  128961["&#91SUBSYS_PERBANK_WEALTH&#93 亲情账户存款购买 <br/> /hundredProfitDeposit/currentToTermSubForKids"]
  class 128961 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  128961_unmatched_1["⚠️ com.hzbank.trans.pbty.commo..."]
  class 128961_unmatched_1 unmatched;
  98124["&#91SUBSYS_PMB_APP&#93 🎯 活期转定期存款提交 <br/> /termDeposit/currentToTermSub"]
  class 98124 apiRoot;
  129617["&#91SUBSYS_PERBANK_WEALTH&#93 定期存款提交 <br/> /deposit/currentToTermSub"]
  class 129617 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  129617_unmatched_1["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_1 unmatched;
  129617_unmatched_2["⚠️ com.hzbank.trans.pbty.commo..."]
  class 129617_unmatched_2 unmatched;
  129617_unmatched_3["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_3 unmatched;
  94420["&#91SUBSYS_PMB_APP&#93 🎯 预约转账建立 <br/> /transfer/transferEstablishment"]
  class 94420 apiRoot;
  94734["&#91SUBSYS_PERBANK_TRANSFER&#93 预约转账建立 <br/> /transferOrderQuery/transferEstablishment"]
  class 94734 ok;
  128201["&#91SUBSYS_DORE_ADPS&#93 预约转账签约 <br/> /agdp/IDIB05/AAGDP31500/v1.0.0"]
  class 128201 ok;
  130239["&#91SUBSYS_DORE_BIDP&#93 单介质账户路由查询 <br/> /idib/IDIB/BIDIB72317/v1.0.0"]
  class 130239 ok;
  130239_unmatched_0["⚠️ SVCIDIB030"]
  class 130239_unmatched_0 unmatched;
  126148["&#91SUBSYS_DORE_BPDP&#93 预约转账签约（个人） <br/> /pdpp/PDPP/BPDPP31200/v1.0.0"]
  class 126148 ok;
  126148_unmatched_0["⚠️ SVCPDPP001"]
  class 126148_unmatched_0 unmatched;
  126148_unmatched_1["⚠️ SVCPDPP005"]
  class 126148_unmatched_1 unmatched;
  126148_unmatched_2["⚠️ SVCPDPP009"]
  class 126148_unmatched_2 unmatched;
  129907["&#91SUBSYS_DORE_BCDP&#93 预约转账签约（对公） <br/> /cdcp/CDCP/BCDCP31200/v1.0.0"]
  class 129907 ok;
  129907_unmatched_0["⚠️ SVCCDCP001"]
  class 129907_unmatched_0 unmatched;
  129907_unmatched_1["⚠️ SVCCDCP005"]
  class 129907_unmatched_1 unmatched;
  129907_unmatched_2["⚠️ SVCCDCP009"]
  class 129907_unmatched_2 unmatched;

  menuRoot -->|菜单第 1 个 API: POST| 98470;
  menuRoot -->|菜单第 2 个 API: POST| 93756;
  menuRoot -->|菜单第 3 个 API: POST| 98142;
  menuRoot -->|菜单第 4 个 API: POST| 95712;
  menuRoot -->|菜单第 5 个 API: POST| 95728;
  menuRoot -->|菜单第 6 个 API: POST| 95744;
  menuRoot -->|菜单第 7 个 API: POST| 98124;
  menuRoot -->|菜单第 8 个 API: POST| 94420;
  93756 -->|feign| 129063;
  98142 -->|feign| 129644;
  95712 -->|feign| 129619;
  95728 -->|feign| 129632;
  95744 -->|feign| 128961;
  128961 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  128961 -->|sdk| 128961_unmatched_1;
  98124 -->|feign| 129617;
  129617 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  129617 -->|unknown| 129617_unmatched_1;
  129617 -->|sdk| 129617_unmatched_2;
  129617 -->|unknown| 129617_unmatched_3;
  94420 -->|unknown| 94734;
  94734 -->|sdk| 128201;
  128201 -->|component| 130239;
  130239 -->|component| 130239_unmatched_0;
  128201 -->|component| 126148;
  126148 -->|component| 126148_unmatched_0;
  126148 -->|component| 126148_unmatched_1;
  126148 -->|component| 126148_unmatched_2;
  128201 -->|component| 129907;
  129907 -->|component| 129907_unmatched_0;
  129907 -->|component| 129907_unmatched_1;
  129907 -->|component| 129907_unmatched_2;
```


#### 存款服务 → 定期存款 → 定期存款购买 → 定期存款

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/termDeposit/termDepositResult "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98470["&#91SUBSYS_PMB_APP&#93 🎯 新公共参数表查询 <br/> /pubServer/pmbPubArgQuery"]
  class 98470 apiRoot;

  menuRoot -->|菜单第 1 个 API: null| 98470;
```


#### 存款服务 → 定期存款 → 定期存款购买

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/termDeposit/termDepositBuyOfSh "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98124["&#91SUBSYS_PMB_APP&#93 🎯 活期转定期存款提交 <br/> /termDeposit/currentToTermSub"]
  class 98124 apiRoot;
  129617["&#91SUBSYS_PERBANK_WEALTH&#93 定期存款提交 <br/> /deposit/currentToTermSub"]
  class 129617 ok;
  126749["&#91SUBSYS_DORE_ADPS&#93 个人账户转账开户 <br/> /agdp/ADPS/AAGDP15002/v1.0.0"]
  class 126749 ok;
  126011["&#91SUBSYS_DORE_BPDP&#93 个人账户转账开户 <br/> /pdpo/PDPO/BPDPO10003/v1.0.0"]
  class 126011 ok;
  126011_unmatched_0["⚠️ SVCPDPO003"]
  class 126011_unmatched_0 unmatched;
  126011_unmatched_1["⚠️ SVCPDPD022"]
  class 126011_unmatched_1 unmatched;
  130791["&#91SUBSYS_DORE_BIDP&#93 介质凭证类型查询 <br/> /idim/IDIM/BIDIM74705/v1.0.0"]
  class 130791 ok;
  126749_unmatched_2["⚠️ BPBDM10059"]
  class 126749_unmatched_2 unmatched;
  126749_unmatched_3["⚠️ BPBDM10061"]
  class 126749_unmatched_3 unmatched;
  130331["&#91SUBSYS_DORE_BIDP&#93 客户已使用印鉴检查 <br/> /idib/IDIB/BIDIB70210/v1.0.0"]
  class 130331 ok;
  130331_unmatched_0["⚠️ SVCIDIB956"]
  class 130331_unmatched_0 unmatched;
  129617_unmatched_1["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_1 unmatched;
  129617_unmatched_2["⚠️ com.hzbank.trans.pbty.commo..."]
  class 129617_unmatched_2 unmatched;
  129617_unmatched_3["⚠️ com.hzbank.trans.pbty.wealt..."]
  class 129617_unmatched_3 unmatched;
  98379["&#91SUBSYS_PMB_APP&#93 🎯 查询公共参数展示信息 <br/> /pubServer/queryPubParamShowMsgs"]
  class 98379 apiRoot;

  menuRoot -->|菜单第 1 个 API: POST| 98124;
  menuRoot -->|菜单第 2 个 API: POST| 98379;
  98124 -->|feign| 129617;
  129617 -->|sdk| 126749;
  126749 -->|component| 126011;
  126011 -->|component| 126011_unmatched_0;
  126011 -->|component| 126011_unmatched_1;
  126749 -->|component| 130791;
  126749 -->|component| 126749_unmatched_2;
  126749 -->|component| 126749_unmatched_3;
  126749 -->|component| 130331;
  130331 -->|component| 130331_unmatched_0;
  129617 -->|unknown| 129617_unmatched_1;
  129617 -->|sdk| 129617_unmatched_2;
  129617 -->|unknown| 129617_unmatched_3;
```


#### 存款服务 → 定期存款 → 定期存款

```mermaid
%%{init: {'flowchart': {'rankSpacing': 100, 'nodeSpacing': 50, 'defaultRenderer': 'dagre'}}}%%
graph LR

  menuRoot[" 📍 &#91 SUBSYS_PMBWEB &#93 <br/>/termDeposit/termDepositOfSh "]
  style menuRoot fill:#90EE90,stroke:#28a745,color:#000,stroke-width:2px

  classDef apiRoot fill:#d1ecf1,stroke:#17a2b8,color:#000;
  classDef ok fill:#d4edda,stroke:#28a745,color:#000;
  classDef unmatched fill:#fff3cd,stroke:#ffc107,color:#000;
  classDef circular fill:#f8d7da,stroke:#dc3545,color:#000;
  classDef maxDepth fill:#e2e3e5,stroke:#6c757d,color:#000;

  98379["&#91SUBSYS_PMB_APP&#93 🎯 查询公共参数展示信息 <br/> /pubServer/queryPubParamShowMsgs"]
  class 98379 apiRoot;

  menuRoot -->|菜单第 1 个 API: POST| 98379;
```