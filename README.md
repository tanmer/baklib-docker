<div align="center">

# 🚀 Baklib Docker Compose 部署

**使用 Docker Compose 部署 Baklib 应用的完整解决方案**

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2.0+-blue.svg)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

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
- [目录结构](#目录结构)
- [主要脚本](#主要脚本)
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
- **自动更新 Traefik**：配置脚本自动同步 Traefik 配置文件，无需手动修改
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

### 📋 前置要求

在开始之前，请确保您的系统满足以下要求：

| 要求 | 版本/规格 |
|------|----------|
| Docker | 20.10+ |
| Docker Compose | 2.0+（或 docker-compose 1.29+） |
| 可用内存 | 至少 8GB |
| 可用磁盘空间 | 至少 20GB |
| 操作系统 | Linux / macOS / Windows (WSL2) |

### 🔑 准备工作

在开始部署之前，请确保您已经：

- ✅ 已向客服申请并获得试用账号
- ✅ 已获取 Docker Registry 账号和密码
- ✅ 已获取产品证书文件 `product.pem`
- ✅ 已安装 Docker 和 Docker Compose

### 📦 安装步骤

#### 1️⃣ 克隆或下载项目

```bash
git clone <repository-url>
cd baklib-docker
```

#### 2️⃣ 放置证书文件

将客服提供的 `product.pem` 证书文件放置到项目根目录：

```bash
# 确保证书文件在项目根目录
ls -la product.pem
```

#### 3️⃣ 运行安装脚本

```bash
chmod +x install.sh
./install.sh
```

安装脚本会自动完成以下操作：

- ✅ 检查 Docker 环境
- ✅ 运行配置脚本（交互式配置）
- ✅ 创建必要的目录
- ✅ 检查必要文件（如 `product.pem`）
- ✅ 自动登录 Docker 镜像仓库（从 `.env` 文件读取 `REGISTRY_USERNAME` 和 `REGISTRY_PASSWORD`）
- ✅ 拉取 Docker 镜像

> 💡 **提示**：
> - 如果 `.env` 文件中已配置 `REGISTRY_USERNAME` 和 `REGISTRY_PASSWORD`，安装脚本会自动使用这些凭证登录
> - 如果未配置，安装脚本会提示您输入 Docker Registry 的账号和密码，请使用客服提供的凭证
> - 配置脚本会自动将 Docker Registry 凭证保存到 `.env` 文件中

#### 4️⃣ 启动服务

```bash
chmod +x start.sh
./start.sh
```

或者直接使用 Docker Compose：

```bash
docker compose up -d
```

这将自动启动所有服务，包括 etcd 认证初始化。

#### 5️⃣ 验证部署

```bash
# 查看服务状态
docker compose ps

# 查看服务日志
docker compose logs -f

# 访问应用（配置完成后）
# 浏览器访问：http://baklib.localhost
```

### 🎉 部署完成

如果所有服务都正常运行，恭喜您！Baklib 私有化部署已完成。

- 🌐 访问地址：`http://baklib.localhost`（根据您的配置）
- 📊 查看 Traefik Dashboard：`http://localhost:8081`
- 📝 查看日志：`docker compose logs -f [服务名]`

## 📁 目录结构

```
baklib-docker/
├── README.md                      # 本文件
├── docker-compose.yml             # Docker Compose 配置文件
├── .env.example                    # 环境变量配置示例
│
├── install.sh                     # 安装脚本
├── config.sh                      # 配置脚本（交互式配置 .env）
├── start.sh                       # 启动服务脚本
├── restart.sh                     # 重启服务脚本
├── stop.sh                        # 停止服务脚本
├── clean.sh                       # 清理脚本（清理所有资源）
├── test-config.sh                 # 配置测试脚本
├── common.sh                      # 公共函数库
│
├── product.pem                    # 产品证书文件（需要创建）
│
├── traefik/                       # Traefik 配置目录
│   ├── etc/
│   │   ├── traefik.yml            # Traefik 主配置文件
│   │   └── dynamic/                # 动态配置文件目录
│   │       ├── common.yml          # 通用配置
│   │       ├── sni-strict.yml      # TLS 安全配置
│   │       └── traefik-dashboard.yml # Dashboard 配置
│   └── README.md                  # Traefik 配置说明
│
├── logs/                          # 日志目录
│   ├── postgresql/                # PostgreSQL 日志
│   └── traefik/                   # Traefik 日志
│
├── storage/                       # 本地存储目录（使用 local 存储时）
└── theme_repositories/            # 主题仓库目录

**注意**：
- `shell` 服务默认不启动，需要使用 `--profile debug` 启动
- 所有数据卷使用命名卷，便于管理和备份
```

## 🛠️ 主要脚本

### install.sh - 安装脚本

一键安装所有依赖和服务：

```bash
./install.sh
```

功能：
- 检查 Docker 环境（Docker 和 Docker Compose）
- 运行配置脚本（`config.sh`，如果 `.env` 不存在会创建）
- 创建必要的目录
- 检查必要文件（如 `product.pem`）
- **自动登录 Docker 镜像仓库**（从 `.env` 文件读取 `REGISTRY_USERNAME` 和 `REGISTRY_PASSWORD`）
- 拉取 Docker 镜像

**注意**：
- 如果 `.env` 文件中已配置 Docker Registry 凭证，会自动使用
- 如果未配置，会提示输入凭证，并保存到 `.env` 文件

### config.sh - 配置脚本

交互式配置 `.env` 文件：

```bash
./config.sh
```

功能：
- 如果 `.env` 不存在，从 `.env.example` 创建（如果 `.env.example` 不存在会报错，需要先创建 `.env` 文件）
- 交互式提示输入各项配置
- **自动检测本地试用环境**：如果主域名为 `baklib.localhost`，自动配置本地环境参数（`SHOW_VERIFICATION_CODE=y`、`INGRESS_PROTOCOL=http`、`INGRESS_PORT=80`、关闭 HTTPS）
- 自动生成 `SECRET_KEY_BASE`
- **自动更新 Traefik 配置文件**：
  - 更新 `traefik/etc/traefik.yml`（ETCD 密码、证书解析器、ACME 邮箱、readTimeout）
  - 更新 `traefik/etc/dynamic/common.yml`（HTTP 到 HTTPS 重定向、请求体大小限制）
  - 更新 `traefik/etc/dynamic/traefik-dashboard.yml`（域名、entryPoints、TLS 配置）
  - 更新 `docker-compose.yml`（Traefik 路由配置）
- **根据存储类型自动调整配置**：
  - 本地存储：`readTimeout` 设置为 20 分钟，`maxRequestBodyBytes` 设置为 10GB
  - 云存储：`readTimeout` 设置为 5 分钟，`maxRequestBodyBytes` 设置为 100MB
- **验证 `.env` 文件语法**：自动检查语法错误（未匹配的引号、变量名格式等）
- 支持非交互模式：`./config.sh --non-interactive`（从 `.env` 文件读取配置并更新 Traefik 配置）

### start.sh - 启动脚本

启动所有服务：

```bash
./start.sh
```

功能：
- 检查 .env 文件和 Docker 环境
- 自动启动所有服务（db、redis、etcd、web、job、traefik）
- 自动初始化 ETCD 认证（如果配置了密码）
- 所有服务会等待 etcd-init 完成后再启动

### restart.sh - 重启脚本

重启所有服务：

```bash
./restart.sh
```

### stop.sh - 停止脚本

停止所有服务：

```bash
./stop.sh
```

### clean.sh - 清理脚本

清理所有容器、网络和数据卷（**危险操作**）：

```bash
./clean.sh
```

**⚠️ 警告**：此操作会删除所有数据，包括数据库数据，请确保已备份！

**安全机制**：
- 需要连续输入 **3 次不同的验证码** 才能执行清理操作
- 每次验证码都是随机生成的 4 位数字
- 如果验证码输入错误，会重置确认次数，需要重新开始
- 这是为了防止误操作导致数据丢失

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

主要配置项在 `.env` 文件中，通过 `config.sh` 脚本进行交互式配置。

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

详细配置说明请参考 `.env.example` 文件（如果存在）。

### Traefik 配置

Traefik 配置文件位于 `traefik/etc/` 目录：

- `traefik.yml`: 主配置文件
- `dynamic/common.yml`: 通用动态配置
- `dynamic/sni-strict.yml`: TLS 安全配置
- `dynamic/traefik-dashboard.yml`: Dashboard 配置

详细说明请参考 `traefik/README.md`。

**重要提示**：
- **配置脚本会自动更新 Traefik 配置文件**，无需手动修改
- `config.sh` 会自动同步以下配置：
  - `traefik.yml`: ETCD 密码、证书解析器、ACME 邮箱、readTimeout（根据存储类型）
  - `common.yml`: HTTP 到 HTTPS 重定向、请求体大小限制（根据存储类型）
  - `traefik-dashboard.yml`: 域名、entryPoints、TLS 配置
  - `docker-compose.yml`: Traefik 路由配置（entryPoints、TLS）
- 如果手动修改了 Traefik 配置文件，运行 `./config.sh` 会覆盖您的修改
- 如果使用 ACME DNS 挑战，需要配置 `DNS_ALIYUN_ACCESS_KEY` 和 `DNS_ALIYUN_SECRET_KEY`

## ❓ 常见问题

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
./restart.sh
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

```bash
# 重新运行配置脚本（推荐）
./config.sh

# 或手动编辑 .env 文件
vim .env

# 如果手动修改了 .env，建议运行非交互模式更新 Traefik 配置
./config.sh --non-interactive

# 修改后重启服务
./restart.sh
```

**注意**：
- 如果只修改了 `.env` 文件，运行 `./config.sh --non-interactive` 会自动更新 Traefik 配置文件
- 配置脚本会自动验证 `.env` 文件语法，如果发现错误会提示修复

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

### 9. 配置脚本验证失败怎么办？

```bash
# 检查 .env 文件语法
./config.sh --non-interactive

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

- [Traefik 配置说明](traefik/README.md) - Traefik 反向代理配置说明
- 环境变量配置：通过 `./config.sh` 脚本交互式配置，或参考 `docker-compose.yml` 中的环境变量定义

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
10. **Traefik 配置**：不要手动修改 Traefik 配置文件，使用 `config.sh` 脚本自动更新
11. **本地试用环境**：使用 `baklib.localhost` 作为主域名时，系统会自动配置本地环境参数，无需手动设置 HTTPS
12. **存储类型影响**：选择不同的存储类型会影响 Traefik 的超时和请求体大小限制，配置脚本会自动调整

### 📞 获取帮助

13. **技术支持**：如遇到问题，请联系客服获取技术支持
14. **证书续期**：证书到期前 30 天，建议联系客服申请续期

## 📝 许可证

[根据项目实际情况填写]

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
