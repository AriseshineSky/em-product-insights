# 架构与边界设计原则

> 依据 GitLab 工程实践（bounded context / module boundary）整理，用于约束本仓库的代码组织方式。
> 包边界由 [Packwerk](https://github.com/Shopify/packwerk) 强制检查（`bundle exec packwerk check`，CI 内执行）。

## 核心原则

### 1. 分层：集成适配器 vs 领域逻辑

- **集成适配器层**：第三方/基础设施 API 的薄封装（认证、请求、错误映射）。不包含任何业务或数据源（source）特有逻辑。
- **领域层**：具体业务能力，按**有界上下文**（bounded context，如 `ProductAudit`）组织，包含自己的模型与服务。

### 2. 依赖方向

- 领域层**只能单向依赖**集成适配器；适配器层**不得反向引用**任何领域代码。
- 领域层调用适配器时通过构造注入（constructor injection），便于测试替换（fake)。

### 3. 职责归属：什么代码放哪里

| 代码 | 应放位置 | 理由 |
| --- | --- | --- |
| HTTP 客户端、认证、请求封装、API 错误映射 | `lib/google_merchant/`（集成适配器） | 与具体 source 无关 |
| Spree 商城 HTTP API 客户端（token v1） | `lib/spree_api/`（集成适配器） | 对接网站产品/订单，与 source 无关 |
| 产品 CRUD/查询、资源名拼装 | `lib/google_merchant/product_service.rb` | 通用 API 操作 |
| 某个 source 的审计/报告（如 merchant 状态） | `lib/product_audit/`（有界上下文） | 领域逻辑，独立演进 |
| 领域模型 | `app/models/<context>/`（如 `product_audit/`） | 与上下文同包 |
| rake 任务、job | `app/` / `lib/tasks/`（根包） | 编排层，只调用领域上下文的公开接口 |

### 4. Packwerk 包清单

- 根包 `package.yml`：`app/`、`config/`、`lib/tasks/`、`lib/*.rb` 顶层入口。**`enforce_dependencies: false`** —— 根包是各上下文共享的底层层，若开启会在依赖图上反向插入边形成环。
- `lib/google_merchant/`：集成适配器，唯一依赖是根包（`.`）。
- `lib/spree_api/`：Spree 商城 HTTP API 适配器，唯一依赖是根包（`.`）。
- `lib/product_audit/`：审计领域上下文，依赖根包（Catalog 模型、ActiveRecord，需声明 `.`）和 `lib/google_merchant`。
- 包间依赖必须显式声明在 `package.yml` 的 `dependencies:` 中，否则 `packwerk check` 报错。
- 依赖图必须**有向无环**（`packwerk validate` 检查）：子包引用根包（声明 `.`）是允许方向；根包不得再声明对子包的依赖。

### 5. 命名约定

- 包命名按目录名（不含 `/`）；依赖声明同样不含斜杠。
- 有新中间层（新包）时：先建目录 + `package.yml`，再移动文件，最后 `packwerk check`。
- 谨慎对待根 `lib/*.rb`：其中的常量属于根包，包内代码引用它们需要将 `.` 声明为依赖。尽量保持根文件只有命名空间定义与 require。

### 6. 变更时的检查清单

1. `bin/rubocop` —— 风格
2. `bundle exec packwerk validate && bundle exec packwerk check` —— 边界
3. 新增独立上下文时先在 `packwerk.yml` 的 `package_paths` 注册

## 强制方式

- 本地：`bundle exec packwerk check`
- CI：`.github/workflows/ci.yml` 的 `packwerk` job（`validate` + `check`），不过则阻断合并