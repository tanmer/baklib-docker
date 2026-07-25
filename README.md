<div align="center">

# 🚀 Baklib Docker Compose 部署

**使用 Docker Compose 部署 Baklib 应用的完整解决方案**

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.0+-blue.svg)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](#许可证)

</div>

---

## 🎯 个人用户私有化部署

> 💡 **新功能**：Baklib 现已支持个人用户私有化部署！您可以在自己的电脑上通过 `baklib.localhost` 域名安装和运行完整的 Baklib 系统，享受私有化部署带来的数据安全和完全控制。

### 📦 概述

Baklib 私有化部署允许个人用户在本地环境运行完整的 Baklib 系统，所有数据存储在本地，确保数据安全和隐私保护。

> 🎯 **快速开始**：扫描下方二维码，添加企业微信客服即可申请试用账号，获取 Docker Registry 账号和产品证书！

### ✨ 申请流程

#### 第一步：联系客服申请试用账号

**📱 扫描下方二维码，添加企业微信客服申请试用账号**

![企业微信客服二维码](contact_me_qr.png)

**或通过以下方式联系：**
- 企业微信：扫描上方二维码
- 提供您的联系方式（邮箱/电话）
- 说明部署需求和使用场景
- 告知预计部署环境（操作系统、硬件配置等）

#### 第二步：获取访问凭证

申请通过后，我们将为您提供：

| 凭证类型 | 说明 | 用途 |
|---------|------|------|
| **Docker Registry 账号** | 用户名和密码 | 用于拉取私有 Docker 镜像 |
| **产品证书** | `product.pem` 文件 | 用于 Baklib 产品授权验证 |

#### 第三步：开始部署

1. 使用提供的 Docker Registry 账号登录
2. 将证书文件 `product.pem` 放置到项目根目录
3. 按照下方 [快速开始](#-快速开始) 指南完成部署

### 💡 部署优势

<div align="center">

| ✅ 完全私有化 | ✅ 本地访问 | ✅ 一键部署 | ✅ 易于维护 |
|:---:|:---:|:---:|:---:|
| 数据存储在本地 | `baklib.localhost` | 自动化脚本 | Docker 容器化 |

</div>

- 🔒 **完全私有化**：数据完全存储在本地，确保数据安全和隐私保护
- 🏠 **本地访问**：通过 `baklib.localhost` 域名本地访问，无需公网
- 🚀 **一键部署**：提供完整的自动化部署脚本，简化安装流程
- 🔧 **易于维护**：Docker 容器化部署，升级和维护简单便捷

---

## 📋 目录

- [个人用户私有化部署](#-个人用户私有化部署)
- [特性](#特性)
- [快速开始](#快速开始)
- [安装与使用（按平台）](#-安装与使用按平台)
- [后期维护](#-后期维护)
- [统一命令速查](#-统一命令速查)
- [目录结构](#目录结构)
- [Docker Compose 与 Rake](#-docker-compose-与-rake)
- [主要脚本与实现说明](#主要脚本与实现说明)
- [服务说明](#服务说明)
- [配置说明](#配置说明)
- [常见问题](#常见问题)
- [相关文档](#相关文档)

## ✨ 核心特性

| 🚀 部署体验 | 🔧 自动化配置 | 🔒 安全可靠 |
|:---:|:---:|:---:|
| 一键安装部署 | 交互式配置脚本 | HTTPS 支持 |
| 完整服务栈 | 自动生成配置 | 证书管理 |
| Docker 容器化 | 环境变量管理 | 数据加密 |

### 🌟 详细特性

#### 🚀 部署与运维

- **一键安装部署**：提供完整的安装和配置脚本，简化部署流程
- **完整服务栈**：包含 Web、Job、PostgreSQL、Redis、ETCD、Traefik 等所有必需服务
- **容器化部署**：基于 Docker Compose，易于管理和维护

#### 🔧 配置与管理

- **自动化配置**：交互式配置脚本，自动生成环境变量文件
- **智能配置**：自动检测本地试用环境（`baklib.localhost`），自动配置相关参数
- **自动更新 Traefik**：`docker compose -f docker-compose.cli.yml run --rm config` 根据 `.env` 将 **`templates/`** 下 `*.yml.erb` 渲染为实际使用的 YAML，无需用 sed 改写配置
- **配置验证**：自动验证 `.env` 文件语法，防止配置错误
- **灵活配置**：支持多种存储、邮件、短信服务配置
- **存储优化**：根据存储类型自动调整 Traefik 超时和请求体大小限制

#### 🔒 安全与证书

- **HTTPS 支持**：支持 HTTP-01 和 DNS-01 两种 ACME 证书申请方式
- **自动证书管理**：Traefik 自动申请和续期 SSL 证书
- **产品证书**：支持产品授权证书验证

#### 📦 存储与扩展

- **多存储支持**：支持本地存储、七牛云、阿里云 OSS、AWS S3
- **高可用架构**：3 节点 ETCD 集群，提供高可用性
- **负载均衡**：Traefik 反向代理，自动服务发现和负载均衡

## 🚀 快速开始

1. **克隆或下载项目**：`git clone <repository-url>` 并 `cd baklib-docker`。
2. **准备凭证**：向客服申请试用账号，获取 Docker Registry 账号/密码及 `product.pem` 证书；安装并启动 Docker（20.10+）与 Docker Compose（2.0+）。
3. **按平台安装**：请查看 **[安装与使用（按平台）](#-安装与使用按平台)**。推荐使用 **`./scripts/cli.sh`**（Windows：`scripts\cli.cmd`），与 `docker compose` 长命令等价（见 **`docker-compose.cli.yml` 顶部注释**）。**注意**：`docker-compose.yml` 与 `traefik/**` 下由模板生成的 YAML **不在仓库中**（见 `.gitignore`），须先执行 **config** 在本地生成后再 `install` / `start`。
4. **部署完成后**：访问配置的主域名（如 `http://baklib.localhost`）、Traefik Dashboard：`http://localhost:8081`；日常维护见 **[后期维护](#-后期维护)**。

> **迁移说明（旧版本用户）**：根目录入口脚本 **`baklib` / `baklib.cmd` 已移除**。请改用：
> | 旧命令 | 新命令 |
> |--------|--------|
> | `./baklib config` | `./scripts/cli.sh config` |
> | `./baklib install` | `./scripts/cli.sh install` |
> | `./baklib start` / `stop` / `restart` | `./scripts/cli.sh start` 等 |
> | `./baklib import-themes` | `./scripts/cli.sh import-themes` |
> | `./baklib clean` / `uninstall` | `./scripts/cli.sh clean` / `uninstall` |

---

## 📦 安装与使用（按平台）

以下按 **Linux / macOS** 与 **Windows** 分别说明安装步骤；日常维护命令见 [后期维护](#-后期维护)。**推荐优先使用 `./scripts/cli.sh`（或 `scripts\cli.cmd`）**，可自动设置 `COMPOSE_PROJECT_NAME`。

### 前置要求（通用）

| 要求 | 说明 |
|------|------|
| Docker | 20.10+，且已启动 |
| Docker Compose | 2.0+（或 docker-compose 1.29+） |
| 内存 | 至少 8GB |
| 磁盘 | 至少 20GB |
| 凭证 | 已向客服申请并获得 Docker Registry 账号、密码及 `product.pem` 证书 |

### Linux / macOS 安装

1. **进入项目目录**
   ```bash
   cd /path/to/baklib-docker
   chmod +x scripts/cli.sh   # 首次建议执行
   ```

2. **放置证书**  
   将客服提供的 `product.pem` 放到项目根目录。

3. **配置**（交互式填写 `.env`，含主域名、存储、**管理员手机号**等；管理员手机号将作为首个用户登录账号，install 时写入数据库）
   ```bash
   ./scripts/cli.sh config
   ```

4. **安装**（登录仓库、拉取镜像；若在 config 中填写了管理员手机号，会临时启动 web 执行 `db:prepare` 并写入首个用户手机号，然后自动清理容器）
   ```bash
   ./scripts/cli.sh install
   ```

5. **启动服务**
   ```bash
   ./scripts/cli.sh start
   ```

6. **导入主题（首次安装必选，需服务已启动）**
   ```bash
   ./scripts/cli.sh import-themes
   ```
   可选：`./scripts/cli.sh import-themes --skip-clone`、`./scripts/cli.sh import-themes --clone-only`。

7. **验证**  
   浏览器访问配置的主域名（如 `http://baklib.localhost`），Traefik Dashboard：`http://localhost:8081`。

### Windows 安装

1. **安装并启动 Docker Desktop**  
   从 [Docker Desktop](https://www.docker.com/products/docker-desktop/) 下载安装，确保 Docker 已运行。

2. **进入项目目录**  
   在 **命令提示符（CMD）** 或 **PowerShell** 中：
   ```cmd
   cd C:\path\to\baklib-docker
   ```

3. **放置证书**  
   将客服提供的 `product.pem` 放到项目根目录。

4. **配置**（含**管理员手机号**，作为首个用户登录账号）
   ```cmd
   scripts\cli.cmd config
   ```

5. **安装**
   ```cmd
   scripts\cli.cmd install
   ```

6. **启动服务**
   ```cmd
   scripts\cli.cmd start
   ```

7. **导入主题（首次安装必选）**
   ```cmd
   scripts\cli.cmd import-themes
   ```
   可选：`scripts\cli.cmd import-themes --skip-clone`、`scripts\cli.cmd import-themes --clone-only`。

8. **验证**  
   浏览器访问配置的主域名，Traefik Dashboard：`http://localhost:8081`。

> **说明**：`config` / `install` / `import-themes` 使用**已发布的 CLI 镜像**（由项目预构建，见 `.env` 中 `BAKLIB_CLI_IMAGE`），无需本地构建，避免国内环境拉取 debian/apt 源失败。若本地调试 CLI 镜像，见 `docs/develop.md`。

---

## 🔧 后期维护

日常运维、改配置、升级、备份等，推荐用 **`./scripts/cli.sh`**（Windows：`scripts\cli.cmd`）；完整 `docker compose` 一行命令见 **`docker-compose.cli.yml` 文件顶部注释**。

| 操作 | 命令 |
|------|------|
| 启动服务 | `./scripts/cli.sh start` |
| 停止服务 | `./scripts/cli.sh stop` |
| 重启服务 | `./scripts/cli.sh restart` |
| 卸载（保留数据） | `./scripts/cli.sh uninstall` |
| 彻底清理（删数据卷） | `./scripts/cli.sh clean` |
| 重新配置 | `./scripts/cli.sh config` |
| 再次准备/拉取镜像 | `./scripts/cli.sh install` |
| 导入/更新主题 | `./scripts/cli.sh import-themes` |

### 修改配置

- **推荐**：运行 `./scripts/cli.sh config` 交互式修改 `.env`，会同步更新 Traefik 等配置。
- **仅改 .env**：编辑 `.env` 后，再执行一次 `./scripts/cli.sh config` 并沿用现有值，或使用非交互：`NON_INTERACTIVE_MODE=true rake config` / `rake config -- --non-interactive`（高级用法）；然后 **重启服务**：`./scripts/cli.sh restart`。

### 更新应用版本

1. 在 `.env` 中修改 `IMAGE_TAG` 为目标版本（如 `v1.32.0`）。
2. 拉取镜像并重启：
   - Linux/macOS：`docker compose pull` 然后 `docker compose restart`
   - Windows：`docker compose pull` 然后 `docker compose restart`

### 备份与恢复

- **数据库**：  
  `docker compose exec db pg_dump -U postgres baklib_production > backup_$(date +%Y%m%d).sql`  
  恢复：`docker compose exec -T db psql -U postgres baklib_production < backup_xxx.sql`
- **数据卷**：PostgreSQL、Redis、ETCD、应用存储等均使用 Docker 命名卷，备份时需备份对应卷或使用 `docker run --rm -v 卷名:/data -v $(pwd):/backup alpine tar czf /backup/卷备份.tar.gz /data` 等方式导出。

### 查看日志与排错

- 所有服务：`docker compose logs -f`
- 单个服务：`docker compose logs -f web`（或 `job`、`traefik`、`db` 等）
- 服务状态：`docker compose ps`

更多排错见 [常见问题](#-常见问题)。

### 证书续期

产品证书 `product.pem` 有效期为 1 年。到期前联系客服获取新证书，替换项目根目录下的 `product.pem` 后重启服务：`./scripts/cli.sh restart`。

---

### 📌 统一命令速查

与上表一致；**卸载**与**彻底清理**的区别：前者保留数据卷，后者执行 `clean` 任务并删除卷（需三次验证码）。完整一行命令见 **`docker-compose.cli.yml` 顶部注释**。

## 🔧 Docker Compose 与 Rake

配置类任务在 **`baklib-cli` 镜像**（`Dockerfile.cli`）内执行 **`rake`**：入口为 **`docker compose -f docker-compose.cli.yml run --rm <服务名>`**，服务内命令见 `docker-compose.cli.yml`（如 `config` → `rake config`）。**`lib/baklib/`** 为 Thor/tty-prompt/dotenv 实现；根目录 **`Rakefile`** 加载 **`lib/tasks/baklib.rake`**。

不想手写长命令时，可用薄封装：**`./scripts/cli.sh <子命令>`**（Linux/macOS）或 **`scripts\cli.cmd <子命令>`**（Windows），与 **`docker-compose.cli.yml`** 顶部注释中的命令等价（子命令：`config`、`install`、`start`、`stop`、`restart`、`uninstall`、`clean`、`import-themes`）。

在项目根目录可查看全部任务说明：

```bash
rake -T
```

| 场景 | Rake 任务 | 说明 |
|------|-----------|------|
| 配置 | `rake config` | 交互/非交互配置 `.env` 并渲染 `templates/**/*.erb` |
| 安装 | `rake install` | 登录仓库、拉取镜像等（通常通过 `docker-compose.cli.yml` 的 `install` 服务跑） |
| 导入主题 | `rake import_themes` | 导入主题；`SKIP_CLONE=1`、`CLONE_ONLY=1` 等见任务 `desc` |
| 清理 | `rake clean` | 彻底清理（三次验证码） |
| 启停主栈 | `rake start` 等 | 与宿主 `docker compose up|stop|restart` 等价；亦可直接使用 `docker compose` |

非交互配置：`NON_INTERACTIVE_MODE=true`，或 `rake config -- --non-interactive`。开发回归可运行 `./scripts/test-config`（本机需 Ruby + `rake` + `tty-prompt` + `dotenv` + `thor`，与 `Dockerfile.cli` 版本一致）。

## 📁 目录结构

```
baklib-docker/
├── README.md                      # 本文件
├── docs/                          # 开发说明（可选，见 develop.md、aliyun-oss-cdn.md）
├── docker-compose.yml             # 本地生成（rake config），已加入 .gitignore
├── templates/                     # ERB 源模板（Rails generator 风格，见 templates/README.md）
│   ├── .env.erb / env_defaults.env  # 生成根目录 .env
│   ├── docker-compose.yml.erb
│   └── traefik/etc/...
├── docker-compose.cli.yml         # CLI 服务（默认拉取 BAKLIB_CLI_IMAGE；含 build 段可本地构建）
├── Dockerfile.cli                 # baklib-cli 镜像定义（见「发布 CLI 镜像」、scripts/build-dev-cli）
│
├── Rakefile                       # Rake 入口：加载 lib/tasks/*.rake（与 baklib-cli 内命令一致）
├── lib/
│   ├── baklib/                    # 配置/安装/主题/清理/生命周期等 Ruby 实现
│   └── tasks/baklib.rake          # Rake 任务定义（desc 即说明）
├── scripts/                       # 辅助脚本（见各文件头注释）
│   ├── cli.sh / cli.cmd           # 可选：封装常用 docker compose 子命令（与 docker-compose.cli.yml 顶部一致）
│   ├── build-dev-cli / run-dev-cli  # 维护者：本地构建 baklib-cli:dev 并跑 rake config
│   ├── push-cli-image             # 维护者：buildx 多架构构建并推送 CLI 镜像
│   └── test-config                # 配置回归测试（NON_INTERACTIVE_MODE=true rake config）
│
├── product.pem                    # 产品证书文件（需要创建）
│
├── traefik/                       # 运行时使用（traefik.yml 等由 rake config 生成，已 .gitignore）
│   ├── etc/
│   │   ├── traefik.yml            # 本地生成
│   │   └── dynamic/
│   │       ├── common.yml         # 本地生成
│   │       ├── sni-strict.yml
│   │       └── traefik-dashboard.yml
│
├── logs/                          # 日志目录
│   ├── postgresql/                # PostgreSQL 日志
│   └── traefik/                   # Traefik 日志
│
├── storage/                       # 本地存储目录（使用 local 存储时）
└── theme_repositories/            # 主题仓库目录

**注意**：
- 根目录 **`docker-compose.yml`** 与 **`traefik/etc/`** 下由模板渲染的 **`*.yml`** 均为 **`rake config` 本地生成**，已写入 `.gitignore`，克隆后须先配置才会出现这些文件。
- `shell` 服务默认不启动，需要使用 `--profile debug` 启动
- 所有数据卷使用命名卷，便于管理和备份
```

### 发布 CLI 镜像（维护者）

CLI 镜像由项目单独构建并推送到仓库，用户端只拉取、不本地构建，避免国内环境拉取 debian/apt 源失败。维护者发布新版本步骤：

1. **构建并推送**（需已登录对应镜像仓库；脚本使用 buildx 构建 **linux/amd64 + linux/arm64** 多平台镜像）：
   ```bash
   ./scripts/push-cli-image registry.devops.tanmer.com/library/baklib-cli:latest
   ```
   或指定版本标签：`./scripts/push-cli-image registry.devops.tanmer.com/library/baklib-cli:v1.0.0`

2. 若需在**国内可访问的镜像站**再发一份，可再执行一次并传入该镜像站地址；用户可在 `.env` 中设置 `BAKLIB_CLI_IMAGE=国内镜像地址` 使用。

构建环境需能访问 `docker.io`（debian:bookworm-slim）及 `download.docker.com`（docker-ce-cli），建议在海外或具备代理的 CI/本机执行。

## 🛠️ 实现说明（Rake）

> **说明**：**config / install / import-themes / clean / start / stop / restart** 的实现均在 **`lib/baklib/`**，由根目录 **`Rakefile`** 与 **`lib/tasks/baklib.rake`** 暴露为 **`rake`** 任务；日常通过 **`docker compose -f docker-compose.cli.yml run --rm <服务名>`** 在容器内执行（见 **`docker-compose.cli.yml`**）。

### install（`rake install`）

通过 **`docker compose -f docker-compose.cli.yml run --rm install`**（需按文件注释传入 `COMPOSE_PROJECT_NAME`、`HOST_PROJECT_ROOT` 等）调用。负责准备镜像（登录仓库、拉取镜像）；若在 config 中配置了 **管理员手机号（ADMIN_PHONE）**，会临时启动 web 容器（`run --rm web`）执行 `bin/rails db:prepare` 初始化数据库，再执行 rails runner 将首个用户登录手机号写入（User 的 `mobile_phone` 字段），然后自动停止并移除所有相关容器，安装完成时无容器在运行。**不执行 config**；需先运行 `config` 生成/更新 `.env` 后再执行。

**步骤顺序**：先 `config`（生成/更新 .env，可填管理员手机号）→ 再 `install`（准备镜像，可选执行 db:prepare 并写入首个用户）→ 再 `start` → `import-themes`

### config（`rake config`）

通过 **`docker compose -f docker-compose.cli.yml run --rm config`** 调用（容器内执行 `rake config`）。交互式配置 `.env` 文件。

功能要点：由 **`templates/.env.erb`** 与 **`templates/env_defaults.env`** 渲染/合并生成 `.env`，交互项、本地试用 `baklib.localhost`、`SECRET_KEY_BASE`、**ERB 渲染** Traefik/Compose、按存储类型调整超时与请求体、校验 `.env` 语法。非交互：`NON_INTERACTIVE_MODE=true` 或 `rake config -- --non-interactive`。

若已有一份 `.env`、只想**重新渲染** YAML 而不跑向导，可执行 **`rake render_yaml`**（与 `lib/baklib/render_yaml.rb` 一致）。

### start / stop / restart

在宿主机项目根目录直接执行 **`docker compose up -d`**、**`docker compose stop`**、**`docker compose restart`**（使用根目录生成的 **`docker-compose.yml`**）。本机若已安装与 **`Dockerfile.cli`** 相同版本的 gem，亦可 **`rake start`** 等，与上者等价。

### import-themes（`rake import_themes`）

首次安装必选，需在服务已正常启动后执行。从 [Gitee theme-wiki](https://gitee.com/baklib/theme-wiki) 克隆到主题卷并执行 `themes:import`。命令行仍支持 `--skip-clone`、`--clone-only`（通过环境变量传入）；亦可直接设置 `SKIP_CLONE=1`、`CLONE_ONLY=1` 等（见 `rake -T import_themes`）。

### clean（`rake clean`）

彻底清理容器、网络与数据卷（**危险操作**）。入口会传入当前目录名作为 `COMPOSE_PROJECT_NAME`，使在容器内执行的 `docker compose down -v` 能正确清理宿主机上的同一项目。

**⚠️ 警告**：此操作会删除所有数据，包括数据库数据，请确保已备份！

**安全机制**：需要连续输入 **3 次不同的验证码** 才能执行清理操作。

### ETCD 认证初始化

ETCD 认证会在每次 `docker compose up` 时自动初始化。`etcd-init` 服务会：
- 等待 etcd 集群所有节点健康就绪
- 检查认证是否已启用
- 如果未启用，自动创建 root 用户并启用认证
- 如果已启用，快速跳过

**重要提示**：
- `etcd-init` 服务会在所有 etcd 节点健康后自动运行
- 所有依赖 etcd 的服务（web、job、traefik）会等待 `etcd-init` 完成后再启动
- 无需手动操作，认证初始化会自动完成
- 如果认证初始化失败，相关服务将无法启动，请检查日志：`docker compose logs etcd-init`

## 🎯 服务说明

### Web 服务

Rails Web 应用服务，处理 HTTP 请求。

- **容器名**: `baklib-web`  
- **健康检查**: `/_healthz` 端点
- **资源限制**: 默认 4 CPU, 4096M 内存（可通过环境变量 `WEB_CONCURRENCY` 和 `WEB_MEMORY` 调整）
- **环境变量**：
  - `RAILS_SERVE_STATIC_FILES`: `y`（启用静态文件服务）
  - `APP_DATABASE_POOL`: 数据库连接池大小（默认 6）
  - `REDIS_POOL`: Redis 连接池大小（默认 7）
  - `WEB_CONCURRENCY`: Web 并发数（可选）

### Job 服务

后台任务服务，处理异步任务。

- **容器名**: `baklib-job`
- **资源限制**: 4 CPU, 4096M 内存
- **配置**: `SOLID_QUEUE_THREADS=5`, `GIT_SYNC_WORKER_COUNT=2`

### PostgreSQL 服务

PostgreSQL 数据库服务。

- **容器名**: `baklib-db`
- **镜像**: `registry.devops.tanmer.com/library/postgres:17.7-trixie`
- **资源限制**: 4 CPU, 8192M 内存
- **数据持久化**: 通过命名卷 `baklib-postgres`

### Redis 服务

Redis 缓存服务。

- **容器名**: `baklib-redis`
- **镜像**: `registry.devops.tanmer.com/library/redis:7.4.7`
- **资源限制**: 2 CPU, 4096M 内存
- **数据持久化**: 通过命名卷 `baklib-redis`

### ETCD 服务（集群模式）

ETCD 分布式键值存储服务，3 节点集群模式。

- **容器名**: `etcd01`, `etcd02`, `etcd03`
- **镜像**: `registry.devops.tanmer.com/library/etcd:v3.5.26`
- **资源限制**: 每个节点 1 CPU, 512M 内存
- **数据持久化**: 通过命名卷 `etcd-data01`, `etcd-data02`, `etcd-data03`
- **认证**: 使用 `ETCD_ROOT_PASSWORD` 环境变量进行 root 用户认证

### Traefik 服务

Traefik 反向代理服务，负责路由和负载均衡。

- **容器名**: `traefik`
- **镜像**: `registry.devops.tanmer.com/library/traefik:v3.3.5`
- **资源限制**: 4 CPU, 2048M 内存
- **端口**:
  - 80: HTTP
  - 443: HTTPS
  - 8081: Traefik Dashboard
- **功能**:
  - 自动服务发现（通过 Docker provider）
  - 文件配置（从 `/etc/traefik/dynamic/` 读取）
  - ETCD 配置（从 etcd 集群读取）
  - ACME 证书自动申请（HTTP-01 和 DNS-01 挑战）
- **环境变量**:
  - `ALICLOUD_ACCESS_KEY`: 阿里云 Access Key（用于 DNS-01 挑战）
  - `ALICLOUD_SECRET_KEY`: 阿里云 Secret Key（用于 DNS-01 挑战）

### Shell 服务（调试模式）

用于调试和运维的 Shell 容器，默认不启动。

- **容器名**: `baklib-shell`
- **镜像**: `registry.devops.tanmer.com/library/alpine:3.19`
- **启动方式**: 使用 `debug` profile 启动
  ```bash
  docker compose --profile debug up -d shell
  ```
- **功能**:
  - 提供调试环境，包含常用工具（psql、redis-cli、etcdctl 等）
  - 挂载项目目录和存储目录，方便调试
  - 预配置数据库、Redis、ETCD 连接环境变量

## ⚙️ 配置说明

### 环境变量配置

主要配置项在 `.env` 文件中，通过 `docker compose -f docker-compose.cli.yml run --rm config`（即 `rake config`）进行交互式配置。

#### 必填配置项

- `SECRET_KEY_BASE`: Rails Secret Key Base（配置脚本会自动生成）
- `POSTGRES_PASSWORD`: PostgreSQL 数据库密码
- `MAIN_DOMAIN`: 主域名
- `SAAS_DOMAIN_SUFFIX`: SaaS 域名后缀（如：`.example.com`）
- `FREE_DOMAIN_SUFFIX`: 免费域名后缀（如：`.apps.example.com`）
- `CNAME_DNS_SUFFIX`: CNAME DNS 后缀（如：`.cname.example.com`）
- `EXTERNAL_IP`: 服务器外部 IP
- `ETCD_ROOT_PASSWORD`: ETCD Root 密码
- `REGISTRY_USERNAME`: Docker 镜像仓库用户名（用于拉取私有镜像）
- `REGISTRY_PASSWORD`: Docker 镜像仓库密码
- `IMAGE_NAME`: Docker 镜像完整路径（如：`registry.devops.tanmer.com/your-account/baklib`）
- `IMAGE_TAG`: Docker 镜像标签（如：`v1.31.0`）
- `BAKLIB_CLI_IMAGE`:（可选）CLI 镜像地址，用于 config/install/import-themes/clean；未设置时使用默认已发布镜像 `registry.devops.tanmer.com/library/baklib-cli:latest`

#### 可选配置项

- **本地试用环境配置**（当 `MAIN_DOMAIN=baklib.localhost` 时自动配置）:
  - `SHOW_VERIFICATION_CODE`: 显示验证码（`y`/`n`，默认 `y`）
  - `INGRESS_PROTOCOL`: 入口协议（`http`/`https`，默认 `http`）
  - `INGRESS_PORT`: 入口端口（默认 `80`）

- **HTTPS 配置**:
  - `MAIN_DOMAIN_CERT_RESOLVER`: 证书解析器（`http01` 或 `alidns`）
  - `SAAS_DOMAIN_CERT_RESOLVER`: SaaS 域名证书解析器
  - `API_DOMAIN_CERT_RESOLVER`: API 域名证书解析器
  - `FREE_DOMAIN_CERT_RESOLVER`: 免费域名证书解析器
  - `ACME_EMAIL`: ACME 证书邮箱
  - `DNS_ALIYUN_ACCESS_KEY`: 阿里云 Access Key（DNS-01 挑战时使用）
  - `DNS_ALIYUN_SECRET_KEY`: 阿里云 Secret Key（DNS-01 挑战时使用）

- **存储配置**:
  - `STORAGE_SAAS_DEFAULT_SERVICE`: 存储服务（`local`/`qinium`/`aliyun`/`amazon`）
  - 根据存储类型配置相应的 Access Key 和 Secret Key

- **短信服务配置**:
  - `TEXT_MESSAGE_ADAPTER`: 短信适配器（`ucloud`/`aliyun`/`qiyewechat`，默认 `qiyewechat`）
  - 根据适配器配置相应的密钥

- **邮件服务配置**:
  - `MAILER_DELIVERY_METHOD`: 邮件发送方式（`smtp`/`sendmail`/`none`，默认 `none`）
  - SMTP 相关配置

- **资源限制配置**:
  - `WEB_CONCURRENCY`: Web 服务 CPU 限制（默认 4）
  - `WEB_MEMORY`: Web 服务内存限制（默认 4096M）
  - `REDIS_POOL`: Redis 连接池大小（默认 7）
  - `APP_DATABASE_POOL`: 数据库连接池大小（默认 6）

- **其他配置**:
  - `GITHUB_PROXY_URL`: GitHub 代理 URL（可选）
  - `SENTRY_DSN`: Sentry 错误追踪 DSN（可选）
  - `SENTRY_CURRENT_ENV`: Sentry 环境名称（可选）
  - `ALLOW_CREATE_ORGANIZATION`: 是否允许创建组织（默认 `true`）
  - `RESERVED_ORGANIZATION_IDENTIFIERS`: 保留的组织标识符（用空格分隔）

详细配置说明见 **`templates/.env.erb`**（注释与条件块）及 **`templates/env_defaults.env`**（默认键值表）。

### Traefik 配置

Traefik 配置文件位于 `traefik/etc/` 目录：

- `traefik.yml`: 主配置文件
- `dynamic/common.yml`: 通用动态配置
- `dynamic/sni-strict.yml`: TLS 安全配置
- `dynamic/traefik-dashboard.yml`: Dashboard 配置

模板与生成路径说明见 **`templates/README.md`**；开发细节见 **`docs/develop.md`**。

**重要提示**：
- **`rake config` 会根据 `.env` 渲染 YAML**：源模板在 **`templates/`**（见 `templates/README.md`），生成物为 `traefik/**` 与根目录 `docker-compose.yml`，请勿只改生成物（下次 config 会被覆盖）；应改 `templates/` 后重新执行 `docker compose -f docker-compose.cli.yml run --rm config`
- 运行 `docker compose -f docker-compose.cli.yml run --rm config` 会通过 `lib/baklib/render_yaml.rb` 渲染模板，同步 ETCD、证书、readTimeout、请求体限制、Dashboard 与 Web 路由的 entryPoints/TLS 等；若仅需预览生成物，可执行 **`rake render_yaml`**
- **baklib-cli 镜像**（`Dockerfile.cli`）基于 Ruby slim，已安装 `rake`、`tty-prompt`、`dotenv`、`thor` 与 `erb`；若在本机直接 `rake config`，需安装与镜像相同版本的 gem
- 如果使用 ACME DNS 挑战，需要配置 `DNS_ALIYUN_ACCESS_KEY` 和 `DNS_ALIYUN_SECRET_KEY`

## ❓ 常见问题

### 0. 提示“服务已在运行”或 “已存在”？

**start**：直接执行 **`docker compose up -d`** 通常会对已运行容器幂等处理；若需确认状态，先执行 **`docker compose ps`**。要应用新镜像或配置，请使用 **`docker compose restart`** 或 **`docker compose up -d --force-recreate`**（视场景而定）。

**install**：若主栈（`web`）已在运行，**`rake install`** 会拒绝继续并提示先停止主栈；若仅需更新镜像，可改 `.env` 中 **`IMAGE_TAG`** 后执行 **`docker compose pull`** 再 **`docker compose restart`**。

若在未先阅读上述约定的情况下直接执行 `docker compose up -d`，可能看到“已存在”（already exists）等提示，属正常现象。执行 **`docker compose -f docker-compose.cli.yml run --rm install`** 时若出现 “Found orphan containers” 警告，是因为主栈已在运行、当前命令使用 `docker-compose.cli.yml`，可忽略。

### 0.1 CLI 镜像拉取失败或想用国内镜像？

CLI 镜像由项目预构建发布，用户只需拉取（不本地构建）。默认镜像为 `registry.devops.tanmer.com/library/baklib-cli:latest`。若拉取失败或希望使用国内镜像站上的 CLI 镜像，可在 `.env` 中设置 `BAKLIB_CLI_IMAGE=你的镜像地址`。

### 1. 如何查看服务日志？

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f web
docker compose logs -f job
docker compose logs -f traefik
```

### 2. 如何进入容器？

```bash
# 进入 web 容器
docker compose exec web bash

# 进入 db 容器
docker compose exec db psql -U postgres -d baklib_production

# 进入 redis 容器
docker compose exec redis redis-cli
```

### 3. 如何更新镜像？

```bash
# 拉取最新镜像
docker compose pull

# 重新创建并启动服务
docker compose restart
```

### 4. 如何备份数据？

```bash
# 备份 PostgreSQL 数据
docker compose exec db pg_dump -U postgres baklib_production > backup.sql

# 备份 Redis 数据（如果配置了持久化）
docker compose exec redis redis-cli SAVE
```

### 5. 健康检查失败怎么办？

```bash
# 检查 web 服务健康状态
docker compose exec web curl -f http://localhost:3000/_healthz

# 检查数据库连接
docker compose exec web rails db:version

# 查看服务状态
docker compose ps
```

### 6. ETCD 认证失败怎么办？

```bash
# 检查 .env 文件中的 ETCD_ROOT_PASSWORD 是否正确
grep ETCD_ROOT_PASSWORD .env

# 查看 etcd-init 容器日志
docker compose logs etcd-init

# 检查 etcd 集群健康状态
docker compose exec etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 endpoint health

# 重新运行 etcd-init（删除容器后重新启动）
docker compose rm -f etcd-init
docker compose up -d etcd-init

# 如果 etcd-init 一直失败，可以手动初始化（不推荐）
# 首先确保 etcd 集群健康，然后进入 etcd-init 容器手动执行初始化命令
```

### 7. 如何修改配置？

**推荐**：交互式修改并同步 Traefik 配置后重启：

1. `docker compose -f docker-compose.cli.yml run --rm config`
2. `docker compose restart`

也可直接手动改 `.env`，再运行配置以渲染模板：

```bash
# 重新运行配置（容器内为 rake config）
docker compose -f docker-compose.cli.yml run --rm config

# 或手动编辑 .env 后非交互渲染（本机已安装与 Dockerfile.cli 相同 gem 时）
NON_INTERACTIVE_MODE=true rake config

# 修改后重启服务
docker compose restart
```

**注意**：
- 如果只修改了 `.env` 文件，运行 `docker compose -f docker-compose.cli.yml run --rm config` 会通过 `lib/baklib/render_yaml.rb` 自动更新 Traefik 等生成文件
- `rake config` 会验证 `.env` 文件语法，如果发现错误会提示修复

### 8. 如何使用 Shell 调试服务？

```bash
# 启动 Shell 服务（调试模式）
docker compose --profile debug up -d shell

# 进入 Shell 容器
docker compose exec shell sh

# 在容器内可以使用预配置的环境变量：
# - PGHOST, PGPORT, PGUSER, PGDATABASE, PGPASSWORD（PostgreSQL）
# - REDIS_HOST, REDIS_PORT（Redis）
# - ETCD_ENDPOINTS, ETCD_USER, ETCD_PASSWORD（ETCD）

# 使用 psql 连接数据库
psql

# 使用 redis-cli 连接 Redis
redis-cli -h $REDIS_HOST -p $REDIS_PORT

# 使用 etcdctl 连接 ETCD
etcdctl --endpoints=$ETCD_ENDPOINTS --user=$ETCD_USER:$ETCD_PASSWORD endpoint health
```

### 9. `rake config` / `.env` 验证失败怎么办？

```bash
# 检查 .env 文件语法
docker compose -f docker-compose.cli.yml run --rm config

# 如果提示语法错误，检查：
# 1. 未匹配的引号（单引号或双引号）
# 2. 变量名中包含非法字符
# 3. 特殊字符未正确转义

# 常见问题：
# - 值中包含引号：使用转义或使用不同的引号类型
# - 值中包含空格：确保值用引号包裹
# - 值中包含特殊字符：使用引号包裹或转义
```

## 📚 相关文档

- **`templates/README.md`**：Traefik / Compose 模板与生成路径对照
- **`docs/develop.md`**：本地 Rake、渲染与 CLI 镜像维护说明
- 环境变量：通过 `docker compose -f docker-compose.cli.yml run --rm config` 交互式配置，或参考生成后的 `docker-compose.yml` 中的环境变量定义

## ⚠️ 注意事项

### 🔐 证书与授权

1. **产品证书有效期**：证书有效期为 **1 年**，到期前请及时联系客服续期
2. **证书文件安全**：确保 `product.pem` 文件存在且有效，不要泄露给他人
3. **证书续期**：证书到期后，系统将无法正常使用，请提前联系客服获取新证书

### 💾 数据安全

4. **数据备份**：定期备份 PostgreSQL 和 Redis 数据卷，建议使用自动化备份方案
5. **存储配置**：如果使用本地存储，确保 `storage/` 目录有足够的磁盘空间
6. **环境变量安全**：`.env` 文件包含敏感信息，不要提交到版本控制系统

### ⚙️ 系统配置

7. **资源限制**：根据实际服务器配置调整 CPU 和内存限制（通过 `WEB_CONCURRENCY` 和 `WEB_MEMORY` 环境变量）
8. **网络安全**：确保数据库和 Redis 不对外暴露端口
9. **Docker Registry**：妥善保管 Docker Registry 账号密码，不要泄露
10. **Traefik 配置**：不要只改已生成的 `traefik.yml` / `docker-compose.yml`，应改 **`templates/`** 下对应 `*.yml.erb` 后执行 `docker compose -f docker-compose.cli.yml run --rm config` 重新渲染
11. **本地试用环境**：使用 `baklib.localhost` 作为主域名时，系统会自动配置本地环境参数，无需手动设置 HTTPS
12. **存储类型影响**：选择不同的存储类型会影响 Traefik 的超时和请求体大小限制，`rake config` 渲染模板时会自动调整

### 📞 获取帮助

13. **技术支持**：如遇到问题，请联系客服获取技术支持
14. **证书续期**：证书到期前 30 天，建议联系客服申请续期

## 📝 许可证

[根据项目实际情况填写]

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
