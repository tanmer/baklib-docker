# Baklib Docker Compose 部署

使用 Docker Compose 部署 Baklib 应用的完整解决方案。

## 📋 目录

- [特性](#特性)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [主要脚本](#主要脚本)
- [服务说明](#服务说明)
- [配置说明](#配置说明)
- [常见问题](#常见问题)
- [相关文档](#相关文档)

## ✨ 特性

- 🚀 **一键安装部署**：提供完整的安装和配置脚本
- 🔧 **自动化配置**：交互式配置脚本，自动生成环境变量文件
- 🔒 **HTTPS 支持**：支持 HTTP-01 和 DNS-01 两种 ACME 证书申请方式
- 📦 **多存储支持**：支持本地存储、七牛云、阿里云 OSS、AWS S3
- 🔐 **ETCD 集群**：3 节点 ETCD 集群，提供高可用性
- 🛡️ **Traefik 反向代理**：自动服务发现、负载均衡、SSL 终止
- 🐳 **完整服务栈**：包含 Web、Job、PostgreSQL、Redis、ETCD、Traefik 等服务

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+（或 docker-compose 1.29+）
- 至少 8GB 可用内存
- 至少 20GB 可用磁盘空间

### 安装步骤

1. **克隆或下载项目**

```bash
git clone <repository-url>
cd baklib-docker
```

2. **运行安装脚本**

```bash
./install.sh
```

安装脚本会自动：
- 检查 Docker 环境
- 运行配置脚本（交互式配置）
- 创建必要的目录
- 检查必要文件（如 `product.pem`）
- 登录 Docker 镜像仓库
- 拉取 Docker 镜像

3. **启动服务**

```bash
./start.sh
```

4. **查看服务状态**

```bash
docker compose ps
```

5. **查看日志**

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f web
docker compose logs -f job
```

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
├── enable-etcd-auth.sh            # 启用 ETCD 认证脚本
├── test-config.sh                 # 配置测试脚本
├── common.sh                      # 公共函数库
│
├── .env                           # 环境变量文件（需要创建，不提交到 git）
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
```

## 🛠️ 主要脚本

### install.sh - 安装脚本

一键安装所有依赖和服务：

```bash
./install.sh
```

功能：
- 检查 Docker 环境
- 运行配置脚本（如果 `.env` 不存在）
- 创建必要的目录
- 检查必要文件
- 登录 Docker 镜像仓库
- 拉取 Docker 镜像

### config.sh - 配置脚本

交互式配置 `.env` 文件：

```bash
./config.sh
```

功能：
- 如果 `.env` 不存在，从 `.env.example` 创建
- 交互式提示输入各项配置
- 自动生成 `SECRET_KEY_BASE`
- 更新 Traefik 配置文件
- 支持非交互模式：`./config.sh --non-interactive`

### start.sh - 启动脚本

启动所有服务：

```bash
./start.sh
```

功能：
- 检查 `.env` 文件是否存在
- 检查 Docker 环境
- 自动初始化 ETCD 认证（如果配置了密码）
- 启动所有服务

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

### enable-etcd-auth.sh - 启用 ETCD 认证

手动启用 ETCD 认证：

```bash
./enable-etcd-auth.sh
```

## 🎯 服务说明

### Web 服务

Rails Web 应用服务，处理 HTTP 请求。

- **容器名**: `baklib-web`  
- **健康检查**: `/_healthz` 端点
- **资源限制**: 默认 4 CPU, 4096M 内存（可通过环境变量调整）

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

## ⚙️ 配置说明

### 环境变量配置

主要配置项在 `.env` 文件中，通过 `config.sh` 脚本进行交互式配置。

#### 必填配置项

- `SECRET_KEY_BASE`: Rails Secret Key Base（使用 `rails secret` 生成）
- `POSTGRES_PASSWORD`: PostgreSQL 数据库密码
- `MAIN_DOMAIN`: 主域名
- `SAAS_DOMAIN_SUFFIX`: SaaS 域名后缀（如：`.example.com`）
- `FREE_DOMAIN_SUFFIX`: 免费域名后缀（如：`.apps.example.com`）
- `CNAME_DNS_SUFFIX`: CNAME DNS 后缀（如：`.cname.example.com`）
- `EXTERNAL_IP`: 服务器外部 IP
- `ETCD_ROOT_PASSWORD`: ETCD Root 密码

#### 可选配置项

- **HTTPS 配置**:
  - `MAIN_DOMAIN_CERT_RESOLVER`: 证书解析器（`http01` 或 `alidns`）
  - `ACME_EMAIL`: ACME 证书邮箱
  - `DNS_ALIYUN_ACCESS_KEY`: 阿里云 Access Key（DNS-01 挑战时使用）
  - `DNS_ALIYUN_SECRET_KEY`: 阿里云 Secret Key（DNS-01 挑战时使用）

- **存储配置**:
  - `STORAGE_SAAS_DEFAULT_SERVICE`: 存储服务（`local`/`qinium`/`aliyun`/`amazon`）
  - 根据存储类型配置相应的 Access Key 和 Secret Key

- **短信服务配置**:
  - `TEXT_MESSAGE_ADAPTER`: 短信适配器（`ucloud`/`aliyun`/`qiyewechat`）
  - 根据适配器配置相应的密钥

- **邮件服务配置**:
  - `MAILER_DELIVERY_METHOD`: 邮件发送方式（`smtp`/`sendmail`/`none`）
  - SMTP 相关配置

详细配置说明请参考 `.env.example` 文件。

### Traefik 配置

Traefik 配置文件位于 `traefik/etc/` 目录：

- `traefik.yml`: 主配置文件
- `dynamic/common.yml`: 通用动态配置
- `dynamic/sni-strict.yml`: TLS 安全配置
- `dynamic/traefik-dashboard.yml`: Dashboard 配置

详细说明请参考 `traefik/README.md`。

**重要提示**：
- 确保 `traefik/etc/traefik.yml` 中 etcd 的密码与 `.env` 文件中的 `ETCD_ROOT_PASSWORD` 一致
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
# 手动启用 ETCD 认证
./enable-etcd-auth.sh

# 或检查 .env 文件中的 ETCD_ROOT_PASSWORD 是否正确
grep ETCD_ROOT_PASSWORD .env
```

### 7. 如何修改配置？

```bash
# 重新运行配置脚本
./config.sh

# 或手动编辑 .env 文件
vim .env

# 修改后重启服务
./restart.sh
```

## 📚 相关文档

- [Traefik 配置说明](traefik/README.md) - Traefik 反向代理配置说明
- [环境变量示例](.env.example) - 所有环境变量的示例和说明

## ⚠️ 注意事项

1. **数据备份**: 定期备份 PostgreSQL 和 Redis 数据卷
2. **资源限制**: 根据实际服务器配置调整 CPU 和内存限制
3. **网络安全**: 确保数据库和 Redis 不对外暴露端口
4. **环境变量安全**: `.env` 文件包含敏感信息，不要提交到版本控制系统
5. **产品证书**: 确保 `product.pem` 文件存在且有效
6. **存储配置**: 如果使用本地存储，确保 `storage/` 目录有足够的磁盘空间

## 📝 许可证

[根据项目实际情况填写]

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
