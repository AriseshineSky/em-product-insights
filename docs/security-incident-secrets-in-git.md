# 敏感信息泄露事件复盘与防范

> 记录一次 `config/master.key` 被提交并推送到 GitHub 的事件经过、已采取的修复措施，以及未来如何避免此类问题。

## 时间线

| 提交 | 内容 | 问题 |
| --- | --- | --- |
| `7dc5c0a` init | 随项目初始化把 `config/master.key`（解密 Rails 凭据的密钥）一并提交并推送 | 敏感文件入库 |
| `c1a27be` 本次修复 | 将 `config/master.key` 移出版本控制并加入 `.gitignore`，同时轮换 Rails 凭据 | 修复（见下） |

## 泄露了什么

- **文件**：`config/master.key`，内容为解密 `config/credentials.yml.enc` 的 32 位十六进制密钥。
- **影响面**：该密钥可解密应用的凭据文件，其中包含生产环境 `secret_key_base`（用于会话签名）。泄露后任何拿到仓库历史的人都可以伪造生产会话 Cookie。凭据文件中不包含数据库密码，因此影响有限。

## 已采取的修复措施

1. `git rm --cached config/master.key` —— 仅从版本控制中移除（本地文件保留）。
2. `.gitignore` 增加 `/config/master.key`，防止再次被跟踪。
3. **轮换凭据**：生成新的 master key，用旧密钥解密 `credentials.yml.enc` 原内容后以新密钥重新加密（内容不变，仅换钥匙）。已验证：
   - 新密钥可以正常解密；
   - 旧密钥已被拒绝。
4. 新的 `config/master.key` 只存在于本地磁盘，**未被提交**。

> 提示：旧的 master key 仍残留在 Git 历史中。由于凭据已轮换，旧密钥已失效，无法再利用。如需彻底抹掉历史中的密钥，可对仓库做强制重写（`git filter-repo` 移除该 blob 后 force push），这会改变历史哈希，须先与协作者确认。

## 为什么会被提交

- Rails 新项目默认生成 `config/master.key`，而该项目的 `.gitignore` 没有纳入标准的 `/config/master.key`（标准 Rails `.gitignore` 模板通常会包含）。
- 提交时没有做敏感信息扫描，`git add -A` 把一切新文件都加了进去。

## 如何避免

### 1. 提交前自查（每次）

```bash
# 查看将被提交的文件，确认没有 .env / *.key / secrets / 私钥
git status --short

# 用 gitleaks 扫描（推荐，可做 CI 门槛）
gitleaks detect --source . --log-opts="--all"

# 快速 grep 排查常见敏感内容
git grep -nE 'BEGIN (RSA|EC|OPENSSH) PRIVATE KEY|SK-[A-Za-z0-9]|postgresql://[^:]+:[^@]+@'
```

### 2. 提交规范

- **不要用无差别 `git add -A`**，先看 `git diff` / `git status` 再逐项添加。
- 记住本仓库的 `.gitignore` 约定：`/.env*`、`/config/master.key`。若新增任何密钥类文件，先确认已被忽略。

### 3. 敏感信息存放约定（本仓库）

| 内容 | 去向 | 是否入库 |
| --- | --- | --- |
| 数据库 / Google / GC 等凭据 | `.env` | 否（`/.env*` 已忽略） |
| Rails 凭据密钥 | `config/master.key`（本地）或 CI/部署机环境变量 `RAILS_MASTER_KEY` | 否 |
| 部署密钥 | 存放在部署机 / 密码管理器，**写入 `.kamal/secrets` 时保持在注释示例状态** | `.kamal/secrets` 本身入库，但只放占位符 |
| 加密后的凭据内容 | `config/credentials.yml.enc` | 是（本就应该入库） |

`.kamal/secrets` 文件自带规范：只允许 `#` 注释与从密码管理器/ENV 引用的写法，**绝不能写入明文密钥**。

### 4. 其他建议

- 在 `.pre-commit-config.yaml` 加入 [gitleaks](https://github.com/gitleaks/gitleaks) hook。
- CI（`.github/workflows/ci.yml`）可加一步 `gitleaks detect`，失败即阻断合并。
- 一旦发现任何密钥入库：先**轮换该密钥**（使泄露值失效），再做历史清理，顺序不可颠倒。

## 密钥泄露通用处置流程

1. 判定泄露范围：哪些文件、是否已推送远端、解密后能拿到什么。
2. 从版本控制移除 + 加入忽略（`git rm --cached` + `.gitignore`）。
3. **轮换/回收密钥**：本仓库用 `ActiveSupport::EncryptedFile` 重新加密，等价于 `bin/rails credentials:edit` 生成新钥匙。
4. 验证：旧密钥必须失效，新密钥可正常使用。
5. 可选：重写历史彻底清理，并 force push。