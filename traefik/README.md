# Traefik 配置文件说明

本目录包含 Traefik 反向代理的配置文件。

## 文件结构

```
traefik/
├── etc/
│   ├── traefik.yml              # Traefik 主配置文件
│   └── dynamic/                 # 动态配置文件目录
│       ├── common.yml          # 通用配置（中间件、路由规则等）
│       ├── sni-strict.yml      # TLS/SSL 安全配置
│       └── traefik-dashboard.yml # Traefik Dashboard 配置
└── README.md                   # 本说明文件
```

## 配置说明

### traefik.yml

Traefik 主配置文件，包含：
- 入口点配置（HTTP、HTTPS、Admin）
- Provider 配置（File、Docker、ETCD）
- 日志配置
- ACME 证书解析器配置

**重要配置项**：

1. **ETCD 密码**（第 26 行）：
   - 当前值：`tanmer.com`
   - **需要修改为与 `.env` 文件中的 `ETCD_ROOT_PASSWORD` 一致**

2. **ACME 邮箱**（第 55、61 行）：
   - 当前值：`acme-angelacademy@xiaohui.dev`
   - 建议根据实际环境修改

3. **证书存储路径**：
   - HTTP-01 挑战：`/etc/traefik/letsencrypt/http01.json`
   - DNS-01 挑战：`/etc/traefik/letsencrypt/alidns.json`
   - 这些文件会自动创建在 `docker-compose/traefik/etc/letsencrypt/` 目录

### dynamic/common.yml

通用动态配置，包含：
- HTTP 到 HTTPS 重定向
- 中间件配置（限流、安全头、压缩等）
- 重定向规则

### dynamic/sni-strict.yml

TLS/SSL 安全配置，包含：
- TLS 版本和加密套件配置
- SNI 严格模式
- ALPN 协议配置

### dynamic/traefik-dashboard.yml

Traefik Dashboard 配置，包含：
- Dashboard 访问路由规则
- Basic Auth 认证配置
- TLS 证书配置

**注意**：
- 当前配置的域名是 `traefik-777.baklib.angelalign.com`，需要根据实际环境修改
- Basic Auth 用户名为 `angelalignbaklib`，密码哈希已配置

## 首次使用

1. **修改 ETCD 密码**：
   ```bash
   # 编辑 traefik.yml，将第 26 行的密码改为与 .env 中的 ETCD_ROOT_PASSWORD 一致
   vim docker-compose/traefik/etc/traefik.yml
   ```

2. **创建证书存储目录**（可选，Traefik 会自动创建）：
   ```bash
   mkdir -p docker-compose/traefik/etc/letsencrypt
   ```

3. **修改 Dashboard 域名**（如果需要）：
   ```bash
   # 编辑 traefik-dashboard.yml，修改域名
   vim docker-compose/traefik/etc/dynamic/traefik-dashboard.yml
   ```

4. **启动 Traefik 服务**：
   ```bash
   cd docker-compose
   docker compose up -d traefik
   ```

## 配置更新

Traefik 会自动监听配置文件的变化并重新加载，无需重启服务。

## 访问 Dashboard

- 本地访问：`http://localhost:8081`
- 通过域名访问：根据 `traefik-dashboard.yml` 中的配置

## 日志

Traefik 日志文件位于：
- 主日志：`docker-compose/logs/traefik/traefik.log`
- 访问日志：`docker-compose/logs/traefik/access.log`

