# 阿里云对象存储（OSS）与 CDN 配置说明

本文说明在 Baklib Docker 部署中，如何将静态资源存储到**阿里云 OSS**，并通过**阿里云 CDN** 加速访问。应用侧通过 `.env` 中的存储相关变量与 `docker-compose.yml` 注入的环境变量生效；变量名需与示例文件完全一致，前缀为 `STORAGE_ALIYUN_`（Aliyun）。若现有 `.env` 仍使用历史错误拼写 `STORAGE_ALIIYUN_*`（双字母 I），请改为 `STORAGE_ALIYUN_*` 后重启服务。

## 前置条件

- 已开通阿里云账号，并完成实名认证。
- 已创建 **RAM 用户**（推荐专用子账号），仅授予对象存储与（若使用 CDN 鉴权）相应只读/读写策略，不要使用主账号 AccessKey 生产环境。
- 已部署或准备部署本仓库中的 Baklib，并完成 `.env` 基础配置。

## 一、配置 OSS

### 1. 创建 Bucket

1. 登录 [对象存储 OSS 控制台](https://oss.console.aliyun.com/)，在目标地域创建 Bucket。
2. **读写权限**：
   - 若资源需通过公网直链或 CDN 匿名访问，可选择「公共读」或与 `STORAGE_ALIYUN_PUBLIC` 策略一致；私有 Bucket 时应用一般通过签名 URL 访问，请与 `STORAGE_ALIYUN_PUBLIC=false` 配合使用。
3. 记录 **Bucket 名称**、**地域**（例如华东1 杭州对应 `oss-cn-hangzhou`）。

### 2. Endpoint（`STORAGE_ALIYUN_ENDPOINT`）

填写 **OSS 外网 Endpoint 主机名**（不含 `https://`），格式一般为：

`oss-<地域 ID>.aliyuncs.com`

例如杭州：`oss-cn-hangzhou.aliyuncs.com`。若使用专有网络或内网访问场景，请按阿里云文档选择对应 Endpoint；与 CDN 回源搭配时，CDN 源站通常配置为该 Bucket 的 OSS 外网访问域名（控制台 Bucket 概览页可查看）。

### 3. RAM 访问密钥

1. 在 [RAM 控制台](https://ram.console.aliyun.com/) 为用户创建 AccessKey（AccessKey ID + AccessKey Secret）。
2. 权限策略至少包含目标 Bucket 的读写（例如系统策略 `AliyunOSSFullAccess` 或更细粒度的自定义策略）。
3. 将密钥填入：

| 环境变量 | 说明 |
|----------|------|
| `STORAGE_ALIYUN_ACCESS_KEY` | AccessKey ID |
| `STORAGE_ALIYUN_SECRET_KEY` | AccessKey Secret |

## 二、配置 CDN（交互向导中为必填）

在 OSS 前增加 CDN 可缩短静态资源访问延迟、分担回源流量。**`./scripts/cli.sh config`（或容器内 `rake config`）选择阿里云 OSS 时，`STORAGE_ALIYUN_ENDPOINT` 与 `STORAGE_ALIYUN_CDN_HOST` 均为必填**；Bucket 为私有（默认）时还需填写 `STORAGE_ALIYUN_CDN_KEY`。

### 1. 添加加速域名

1. 打开 [CDN 控制台](https://cdn.console.aliyun.com/)，「域名管理」中新增域名。
2. **业务类型**一般选择「图片小文件」或「大文件下载」，按实际资源类型选择。
3. **源站信息**：源站类型选择「OSS 域名」，选中上一步创建的 Bucket（或填写 Bucket 的外网 Endpoint 域名，与控制台提示一致即可）。

### 2. DNS CNAME

在域名 DNS 服务商处，将用于加速的域名（如 `cdn.example.com`）CNAME 到 CDN 控制台为该域名分配的 CNAME 地址。

### 3. HTTPS（推荐）

在 CDN 控制台为该域名配置 HTTPS 证书（可使用阿里云证书服务或上传自有证书），避免浏览器混合内容警告。

### 4. 缓存与刷新

- 根据资源更新频率配置缓存规则；发布新版本后若遇缓存不刷新，可在控制台使用 **URL 刷新** 或 **目录刷新**。
- 若开启 **URL 鉴权**，需在控制台生成/配置鉴权主 Key，并与应用侧 `STORAGE_ALIYUN_CDN_KEY` 等配置保持一致（具体算法与参数以 Baklib 产品文档为准）；未使用 URL 鉴权时该变量可留空。

### 5. 填写 CDN 相关变量

| 环境变量 | 说明 |
|----------|------|
| `STORAGE_ALIYUN_CDN_HOST` | CDN 访问域名，建议带协议，例如 `https://cdn.example.com`（以实际控制台与产品要求为准） |
| `STORAGE_ALIYUN_CDN_KEY` | CDN URL 鉴权相关密钥；未启用鉴权可留空 |

## 三、在 Baklib Docker 中启用阿里云存储

### 1. 设置默认存储为阿里云

在 `.env` 中设置：

```bash
STORAGE_SAAS_DEFAULT_SERVICE=aliyun
```

### 2. 完整变量示例（请替换为真实值）

```bash
STORAGE_SAAS_DEFAULT_SERVICE=aliyun

STORAGE_ALIYUN_ACCESS_KEY=LTAIxxxxxxxxxxxx
STORAGE_ALIYUN_SECRET_KEY=xxxxxxxxxxxxxxxx
STORAGE_ALIYUN_BUCKET=your-bucket-name
STORAGE_ALIYUN_ENDPOINT=oss-cn-hangzhou.aliyuncs.com

# 可选：CDN
STORAGE_ALIYUN_CDN_HOST=https://cdn.example.com
STORAGE_ALIYUN_CDN_KEY=

# 是否公开读（true/false，按 Bucket 与应用需求填写）
STORAGE_ALIYUN_PUBLIC=false
```

### 3. 与 `ASSET_CDN_HOST` 的关系

`docker-compose.yml` 中 Web 服务支持 `ASSET_CDN_HOST`。若产品说明要求将静态资源统一指向独立 CDN 域名，可在 `.env` 中设置：

```bash
ASSET_CDN_HOST=https://cdn.example.com
```

是否与 `STORAGE_ALIYUN_CDN_HOST` 填同一域名，以 Baklib 版本说明为准；两者都涉及「资源对外访问域名」时，请避免互相矛盾。

### 4. 应用配置

- 可直接编辑 `.env`，或运行 `./scripts/cli.sh config`（容器内为 `rake config`），在交互流程中选择存储类型 **aliyun**，按提示填入上述项。
- 修改存储相关变量后，需重启服务，例如：`./scripts/cli.sh restart`。

## 四、验证与常见问题

1. **上传与访问**：在 Baklib 中上传附件或图片，在 OSS 控制台对应 Bucket 中应能看到对象；浏览器访问资源链接应返回 200（私有 Bucket 需使用带签名的 URL）。
2. **CDN 未命中 / 旧内容**：检查缓存规则，必要时做 URL 刷新；确认 CNAME 已生效。
3. **403 /签名错误**：核对 RAM 权限、Bucket 策略、`STORAGE_ALIYUN_PUBLIC` 与是否启用 CDN 鉴权一致。
4. **Endpoint 错误**：地域与 Endpoint 必须匹配；不要混入内网 Endpoint 到仅公网可达的环境。

更多环境变量名称与占位说明见 `templates/.env.erb` 与 `templates/env_defaults.env`。
