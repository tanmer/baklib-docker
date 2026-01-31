#!/bin/bash

# 配置脚本
# 用于交互式配置 .env 文件
# 支持非交互模式：直接读取 .env 文件并更新配置文件

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# 允许 Ctrl+C 立即终止配置流程（含在 Docker 容器内运行时）
trap 'echo ""; echo "已取消配置"; exit 130' INT

# 检查是否是非交互模式
NON_INTERACTIVE=false
if [ "$1" = "--non-interactive" ] || [ "$1" = "-n" ] || [ "${NON_INTERACTIVE_MODE}" = "true" ]; then
    NON_INTERACTIVE=true
fi

echo "=========================================="
echo "⚙️  Baklib Docker Compose 配置脚本"
if [ "$NON_INTERACTIVE" = "true" ]; then
    echo "（非交互模式：从 .env 文件读取配置）"
fi
echo "=========================================="
echo ""

# 如果 .env 不存在，从示例文件创建
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        print_success "已从示例文件创建 .env"
    else
        print_error "找不到 .env.example 文件"
        exit 1
    fi
fi

if [ "$NON_INTERACTIVE" = "true" ]; then
    # 非交互模式：直接从 .env 读取配置
    print_info "非交互模式：从 .env 文件读取配置..."
    MAIN_DOMAIN=$(read_env_value "MAIN_DOMAIN")
    SAAS_DOMAIN_SUFFIX=$(read_env_value "SAAS_DOMAIN_SUFFIX")
    FREE_DOMAIN_SUFFIX=$(read_env_value "FREE_DOMAIN_SUFFIX")
    CNAME_DNS_SUFFIX=$(read_env_value "CNAME_DNS_SUFFIX")

    # 判断是否启用 HTTPS
    MAIN_DOMAIN_CERT_RESOLVER=$(read_env_value "MAIN_DOMAIN_CERT_RESOLVER")
    if [ -n "$MAIN_DOMAIN_CERT_RESOLVER" ]; then
        ENABLE_HTTPS="y"
        CERT_RESOLVER_DEFAULT="$MAIN_DOMAIN_CERT_RESOLVER"
        if [ "$MAIN_DOMAIN_CERT_RESOLVER" = "alidns" ]; then
            CERT_METHOD="2"
            DNS_ALIYUN_ACCESS_KEY=$(read_env_value "DNS_ALIYUN_ACCESS_KEY")
            DNS_ALIYUN_SECRET_KEY=$(read_env_value "DNS_ALIYUN_SECRET_KEY")
        else
            CERT_METHOD="1"
            DNS_ALIYUN_ACCESS_KEY=""
            DNS_ALIYUN_SECRET_KEY=""
        fi
        ACME_EMAIL=$(read_env_value "ACME_EMAIL")
    else
        ENABLE_HTTPS="n"
        MAIN_DOMAIN_CERT_RESOLVER=""
        SAAS_DOMAIN_CERT_RESOLVER=""
        API_DOMAIN_CERT_RESOLVER=""
        FREE_DOMAIN_CERT_RESOLVER=""
        DNS_ALIYUN_ACCESS_KEY=""
        DNS_ALIYUN_SECRET_KEY=""
        ACME_EMAIL=""
    fi

    EXTERNAL_IP=$(read_env_value "EXTERNAL_IP")
    POSTGRES_PASSWORD=$(read_env_value "POSTGRES_PASSWORD")
    ETCD_ROOT_PASSWORD=$(read_env_value "ETCD_ROOT_PASSWORD")
    SECRET_KEY_BASE=$(read_env_value "SECRET_KEY_BASE")
    ADMIN_PHONE=$(read_env_value "ADMIN_PHONE")

    # 存储配置
    STORAGE_SAAS_DEFAULT_SERVICE=$(read_env_value "STORAGE_SAAS_DEFAULT_SERVICE")
    STORAGE_SAAS_DEFAULT_SERVICE=${STORAGE_SAAS_DEFAULT_SERVICE:-local}

    # 根据存储类型读取相关配置
    case "$STORAGE_SAAS_DEFAULT_SERVICE" in
        qinium)
            STORAGE_QINIU_ACCESS_KEY=$(read_env_value "STORAGE_QINIU_ACCESS_KEY")
            STORAGE_QINIU_SECRET_KEY=$(read_env_value "STORAGE_QINIU_SECRET_KEY")
            STORAGE_QINIU_BUCKET=$(read_env_value "STORAGE_QINIU_BUCKET")
            STORAGE_QINIU_PROTOCOL=$(read_env_value "STORAGE_QINIU_PROTOCOL")
            STORAGE_QINIU_DOMAIN=$(read_env_value "STORAGE_QINIU_DOMAIN")
            ;;
        aliyun)
            STORAGE_ALIIYUN_ACCESS_KEY=$(read_env_value "STORAGE_ALIIYUN_ACCESS_KEY")
            STORAGE_ALIIYUN_SECRET_KEY=$(read_env_value "STORAGE_ALIIYUN_SECRET_KEY")
            STORAGE_ALIIYUN_BUCKET=$(read_env_value "STORAGE_ALIIYUN_BUCKET")
            STORAGE_ALIIYUN_ENDPOINT=$(read_env_value "STORAGE_ALIIYUN_ENDPOINT")
            STORAGE_ALIIYUN_CDN_HOST=$(read_env_value "STORAGE_ALIIYUN_CDN_HOST")
            STORAGE_ALIIYUN_CDN_KEY=$(read_env_value "STORAGE_ALIIYUN_CDN_KEY")
            STORAGE_ALIIYUN_PUBLIC=$(read_env_value "STORAGE_ALIIYUN_PUBLIC")
            ;;
        amazon)
            STORAGE_AWS_ACCESS_KEY=$(read_env_value "STORAGE_AWS_ACCESS_KEY")
            STORAGE_AWS_SECRET_KEY=$(read_env_value "STORAGE_AWS_SECRET_KEY")
            STORAGE_AWS_BUCKET=$(read_env_value "STORAGE_AWS_BUCKET")
            STORAGE_AWS_REGION=$(read_env_value "STORAGE_AWS_REGION")
            STORAGE_AWS_PUBLIC=$(read_env_value "STORAGE_AWS_PUBLIC")
            STORAGE_AWS_EXPIRES_IN=$(read_env_value "STORAGE_AWS_EXPIRES_IN")
            STORAGE_AWS_CDN_HOST=$(read_env_value "STORAGE_AWS_CDN_HOST")
            STORAGE_AWS_CDN_PUBLIC_KEY_ID=$(read_env_value "STORAGE_AWS_CDN_PUBLIC_KEY_ID")
            STORAGE_AWS_CDN_PRIVATE_KEY_BASE64=$(read_env_value "STORAGE_AWS_CDN_PRIVATE_KEY_BASE64")
            ;;
        local)
            ;;
    esac

    # Docker 镜像仓库配置
    REGISTRY_USERNAME=$(read_env_value "REGISTRY_USERNAME")
    REGISTRY_PASSWORD=$(read_env_value "REGISTRY_PASSWORD")
    IMAGE_NAME=$(read_env_value "IMAGE_NAME")
    IMAGE_TAG=$(read_env_value "IMAGE_TAG")

    print_success "已从 .env 文件读取配置"
    echo ""
else
    # 交互模式：提示用户输入
    echo "=========================================="
    echo "📝 请填写以下配置项（按回车使用默认值）"
    echo "=========================================="
    echo ""

    # 基础配置
    MAIN_DOMAIN=$(prompt_config "MAIN_DOMAIN" "主域名")

    # 检查是否是本地试用环境
    IS_LOCAL_TRIAL=false
    if [ "$MAIN_DOMAIN" = "baklib.localhost" ]; then
        IS_LOCAL_TRIAL=true
        print_info "检测到本地试用环境 (baklib.localhost)，自动配置本地环境参数..."
        SHOW_VERIFICATION_CODE="y"
        INGRESS_PROTOCOL="http"
        INGRESS_PORT="80"
        ENABLE_HTTPS="n"
        MAIN_DOMAIN_CERT_RESOLVER=""
        SKIP_HTTPS_CONFIG="true"
        print_success "已自动设置：SHOW_VERIFICATION_CODE=y, INGRESS_PROTOCOL=http, INGRESS_PORT=80, HTTPS=关闭"
        echo ""
    fi

    # 根据主域名生成示例提示
    if [ -n "$MAIN_DOMAIN" ]; then
        SAAS_DOMAIN_SUFFIX_EXAMPLE=".${MAIN_DOMAIN}"
        FREE_DOMAIN_SUFFIX_EXAMPLE=".apps.${MAIN_DOMAIN}"
        CNAME_DNS_SUFFIX_EXAMPLE=".cname.${MAIN_DOMAIN}"
    else
        # 如果主域名为空，使用默认示例
        SAAS_DOMAIN_SUFFIX_EXAMPLE=".example.com"
        FREE_DOMAIN_SUFFIX_EXAMPLE=".apps.example.com"
        CNAME_DNS_SUFFIX_EXAMPLE=".cname.example.com"
    fi

    SAAS_DOMAIN_SUFFIX=$(prompt_config "SAAS_DOMAIN_SUFFIX" "组织域名后缀（如：${SAAS_DOMAIN_SUFFIX_EXAMPLE}）")
    FREE_DOMAIN_SUFFIX=$(prompt_config "FREE_DOMAIN_SUFFIX" "站点域名后缀（如：${FREE_DOMAIN_SUFFIX_EXAMPLE}）")
    CNAME_DNS_SUFFIX=$(prompt_config "CNAME_DNS_SUFFIX" "CNAME域名后缀（如：${CNAME_DNS_SUFFIX_EXAMPLE}）")

    echo ""
    echo "=========================================="
    echo "🔒 HTTPS 配置"
    echo "=========================================="
    echo ""

    # HTTPS 配置
    # 如果是本地试用环境，跳过 HTTPS 配置
    if [ "$IS_LOCAL_TRIAL" = "true" ]; then
        print_info "本地试用环境，跳过 HTTPS 配置"
        echo ""
    else
        ENABLE_HTTPS_DEFAULT=$(read_env_value "MAIN_DOMAIN_CERT_RESOLVER")
        if [ -n "$ENABLE_HTTPS_DEFAULT" ]; then
        # 检测到已配置 HTTPS，显示当前状态并询问是否修改
        print_info "当前 HTTPS 状态：已开启"
        CERT_RESOLVER_CURRENT="$ENABLE_HTTPS_DEFAULT"
        if [ "$CERT_RESOLVER_CURRENT" = "alidns" ]; then
            print_info "当前证书签发方式：DNS-01 挑战（阿里云 DNS）"
        else
            print_info "当前证书签发方式：HTTP-01 挑战"
        fi
        echo ""
        echo -n "是否要修改 HTTPS 配置？(y/n) [n]: "
        read MODIFY_HTTPS
        MODIFY_HTTPS=$(echo "$MODIFY_HTTPS" | tr '[:upper:]' '[:lower:]')
        MODIFY_HTTPS=${MODIFY_HTTPS:-n}

        if [ "$MODIFY_HTTPS" = "y" ] || [ "$MODIFY_HTTPS" = "yes" ]; then
            # 用户选择修改，询问是否关闭 HTTPS
            echo ""
            echo -n "是否关闭 HTTPS？(y/n) [n]: "
            read CLOSE_HTTPS
            CLOSE_HTTPS=$(echo "$CLOSE_HTTPS" | tr '[:upper:]' '[:lower:]')
            CLOSE_HTTPS=${CLOSE_HTTPS:-n}

            if [ "$CLOSE_HTTPS" = "y" ] || [ "$CLOSE_HTTPS" = "yes" ]; then
                ENABLE_HTTPS="n"
            else
                ENABLE_HTTPS="y"
            fi
        else
            # 用户选择不修改，保持当前状态，跳过后续 HTTPS 配置
            ENABLE_HTTPS="y"
            SKIP_HTTPS_CONFIG="true"
        fi
        else
            # 未配置 HTTPS，询问是否开启
            print_info "当前 HTTPS 状态：未开启"
            echo ""
            echo -n "是否开启 HTTPS？(y/n) [n]: "
            read ENABLE_HTTPS
            ENABLE_HTTPS=${ENABLE_HTTPS:-n}
            SKIP_HTTPS_CONFIG="false"
        fi

        ENABLE_HTTPS=$(echo "$ENABLE_HTTPS" | tr '[:upper:]' '[:lower:]')
    fi

    ENABLE_HTTPS=$(echo "$ENABLE_HTTPS" | tr '[:upper:]' '[:lower:]')

    if [ "$ENABLE_HTTPS" = "y" ] || [ "$ENABLE_HTTPS" = "yes" ]; then
        echo ""
        print_info "HTTPS 证书签发方式："
        echo "  1. HTTP-01 挑战（需要开放 80 端口）"
        echo "  2. DNS-01 挑战（使用阿里云 DNS）"
        echo ""
        CERT_RESOLVER_DEFAULT=$(read_env_value "MAIN_DOMAIN_CERT_RESOLVER")
        if [ -n "$CERT_RESOLVER_DEFAULT" ]; then
            echo -n "选择证书签发方式 (1/2) [$CERT_RESOLVER_DEFAULT]: "
        else
            echo -n "选择证书签发方式 (1/2) [1]: "
        fi
        read CERT_METHOD
        CERT_METHOD=${CERT_METHOD:-${CERT_RESOLVER_DEFAULT:-1}}

        if [ "$SKIP_HTTPS_CONFIG" != "true" ]; then
            if [ "$CERT_METHOD" = "2" ]; then
                MAIN_DOMAIN_CERT_RESOLVER="alidns"
                SAAS_DOMAIN_CERT_RESOLVER="alidns"
                API_DOMAIN_CERT_RESOLVER="alidns"
                FREE_DOMAIN_CERT_RESOLVER="alidns"

                echo ""
                print_info "配置阿里云 DNS（用于 DNS-01 挑战）"
                DNS_ALIYUN_ACCESS_KEY=$(prompt_config "DNS_ALIYUN_ACCESS_KEY" "阿里云 Access Key ID")
                DNS_ALIYUN_SECRET_KEY=$(prompt_config "DNS_ALIYUN_SECRET_KEY" "阿里云 Access Key Secret")
            else
                MAIN_DOMAIN_CERT_RESOLVER="http01"
                SAAS_DOMAIN_CERT_RESOLVER="http01"
                API_DOMAIN_CERT_RESOLVER="http01"
                FREE_DOMAIN_CERT_RESOLVER="http01"
                DNS_ALIYUN_ACCESS_KEY=""
                DNS_ALIYUN_SECRET_KEY=""
            fi

            # ACME 邮箱配置
            echo ""
            ACME_EMAIL=$(prompt_config "ACME_EMAIL" "ACME 证书邮箱（用于 Let's Encrypt 通知）")
            if [ -z "$ACME_EMAIL" ]; then
                ACME_EMAIL="acme-your-email@xiaohui.dev"
            fi
        else
            # 保持原有配置
            MAIN_DOMAIN_CERT_RESOLVER="$ENABLE_HTTPS_DEFAULT"
            SAAS_DOMAIN_CERT_RESOLVER=$(read_env_value "SAAS_DOMAIN_CERT_RESOLVER")
            API_DOMAIN_CERT_RESOLVER=$(read_env_value "API_DOMAIN_CERT_RESOLVER")
            FREE_DOMAIN_CERT_RESOLVER=$(read_env_value "FREE_DOMAIN_CERT_RESOLVER")
            DNS_ALIYUN_ACCESS_KEY=$(read_env_value "DNS_ALIYUN_ACCESS_KEY")
            DNS_ALIYUN_SECRET_KEY=$(read_env_value "DNS_ALIYUN_SECRET_KEY")
            ACME_EMAIL=$(read_env_value "ACME_EMAIL")
        fi
    else
        MAIN_DOMAIN_CERT_RESOLVER=""
        SAAS_DOMAIN_CERT_RESOLVER=""
        API_DOMAIN_CERT_RESOLVER=""
        FREE_DOMAIN_CERT_RESOLVER=""
        DNS_ALIYUN_ACCESS_KEY=""
        DNS_ALIYUN_SECRET_KEY=""
        ACME_EMAIL=""
    fi

    echo ""
    echo "=========================================="
    echo "💾 存储配置"
    echo "=========================================="
    echo ""

    # 存储配置
    STORAGE_DEFAULT=$(read_env_value "STORAGE_SAAS_DEFAULT_SERVICE")
    if [ -z "$STORAGE_DEFAULT" ]; then
        STORAGE_DEFAULT="local"
    fi

    echo "存储类型："
    echo "  1. local - 本地存储"
    echo "  2. qinium - 七牛云"
    echo "  3. aliyun - 阿里云 OSS"
    echo "  4. amazon - AWS S3"
    echo ""
    echo -n "选择存储类型 (1/2/3/4) [$STORAGE_DEFAULT]: "
    read STORAGE_CHOICE

    case "$STORAGE_CHOICE" in
        1|local|"")
            STORAGE_SAAS_DEFAULT_SERVICE="local"
            ;;
        2|qinium)
            STORAGE_SAAS_DEFAULT_SERVICE="qinium"
            ;;
        3|aliyun)
            STORAGE_SAAS_DEFAULT_SERVICE="aliyun"
            ;;
        4|amazon)
            STORAGE_SAAS_DEFAULT_SERVICE="amazon"
            ;;
        *)
            STORAGE_SAAS_DEFAULT_SERVICE=${STORAGE_CHOICE:-$STORAGE_DEFAULT}
            ;;
    esac

    # 根据存储类型配置
    case "$STORAGE_SAAS_DEFAULT_SERVICE" in
        qinium)
            echo ""
            print_info "配置七牛云存储"
            STORAGE_QINIU_ACCESS_KEY=$(prompt_config "STORAGE_QINIU_ACCESS_KEY" "七牛云 Access Key")
            STORAGE_QINIU_SECRET_KEY=$(prompt_config "STORAGE_QINIU_SECRET_KEY" "七牛云 Secret Key")
            STORAGE_QINIU_BUCKET=$(prompt_config "STORAGE_QINIU_BUCKET" "七牛云 Bucket 名称")
            STORAGE_QINIU_PROTOCOL=$(prompt_config "STORAGE_QINIU_PROTOCOL" "七牛云协议 (http/https) [https]")
            STORAGE_QINIU_PROTOCOL=${STORAGE_QINIU_PROTOCOL:-https}
            STORAGE_QINIU_DOMAIN=$(prompt_config "STORAGE_QINIU_DOMAIN" "七牛云域名")
            ;;
        aliyun)
            echo ""
            print_info "配置阿里云 OSS"
            STORAGE_ALIIYUN_ACCESS_KEY=$(prompt_config "STORAGE_ALIIYUN_ACCESS_KEY" "阿里云 Access Key ID")
            STORAGE_ALIIYUN_SECRET_KEY=$(prompt_config "STORAGE_ALIIYUN_SECRET_KEY" "阿里云 Access Key Secret")
            STORAGE_ALIIYUN_BUCKET=$(prompt_config "STORAGE_ALIIYUN_BUCKET" "阿里云 OSS Bucket 名称")
            STORAGE_ALIIYUN_ENDPOINT=$(prompt_config "STORAGE_ALIIYUN_ENDPOINT" "阿里云 OSS Endpoint（可选）")
            STORAGE_ALIIYUN_CDN_HOST=$(prompt_config "STORAGE_ALIIYUN_CDN_HOST" "阿里云 CDN 域名（可选）")
            STORAGE_ALIIYUN_CDN_KEY=$(prompt_config "STORAGE_ALIIYUN_CDN_KEY" "阿里云 CDN Key（可选）")
            STORAGE_ALIIYUN_PUBLIC=$(prompt_config "STORAGE_ALIIYUN_PUBLIC" "是否公开访问 (true/false) [false]")
            STORAGE_ALIIYUN_PUBLIC=${STORAGE_ALIIYUN_PUBLIC:-false}
            ;;
        amazon)
            echo ""
            print_info "配置 AWS S3"
            STORAGE_AWS_ACCESS_KEY=$(prompt_config "STORAGE_AWS_ACCESS_KEY" "AWS Access Key ID")
            STORAGE_AWS_SECRET_KEY=$(prompt_config "STORAGE_AWS_SECRET_KEY" "AWS Secret Access Key")
            STORAGE_AWS_BUCKET=$(prompt_config "STORAGE_AWS_BUCKET" "AWS S3 Bucket 名称")
            STORAGE_AWS_REGION=$(prompt_config "STORAGE_AWS_REGION" "AWS 区域")
            STORAGE_AWS_PUBLIC=$(prompt_config "STORAGE_AWS_PUBLIC" "是否公开访问 (true/false) [false]")
            STORAGE_AWS_PUBLIC=${STORAGE_AWS_PUBLIC:-false}
            STORAGE_AWS_EXPIRES_IN=$(prompt_config "STORAGE_AWS_EXPIRES_IN" "签名过期时间（秒）[3600]")
            STORAGE_AWS_EXPIRES_IN=${STORAGE_AWS_EXPIRES_IN:-3600}
            STORAGE_AWS_CDN_HOST=$(prompt_config "STORAGE_AWS_CDN_HOST" "AWS CloudFront 域名（可选）")
            STORAGE_AWS_CDN_PUBLIC_KEY_ID=$(prompt_config "STORAGE_AWS_CDN_PUBLIC_KEY_ID" "CloudFront Public Key ID（可选）")
            STORAGE_AWS_CDN_PRIVATE_KEY_BASE64=$(prompt_config "STORAGE_AWS_CDN_PRIVATE_KEY_BASE64" "CloudFront Private Key Base64（可选）")
            ;;
        local)
            # 本地存储不需要额外配置
            ;;
    esac

    echo ""
    echo "=========================================="
    echo "📧 其他重要配置"
    echo "=========================================="
    echo ""

    # 其他重要配置
    EXTERNAL_IP=$(prompt_config "EXTERNAL_IP" "服务器外部 IP 地址")
    POSTGRES_PASSWORD=$(prompt_config "POSTGRES_PASSWORD" "PostgreSQL 数据库密码")
    ETCD_ROOT_PASSWORD=$(prompt_config "ETCD_ROOT_PASSWORD" "ETCD Root 密码")

    echo ""
    print_info "管理员账号（首个用户登录手机号，install 时将写入数据库）"
    ADMIN_PHONE=$(prompt_config "ADMIN_PHONE" "管理员手机号（首个用户登录账号）")

    echo ""
    print_info "生成 SECRET_KEY_BASE..."
    SECRET_KEY_BASE_DEFAULT=$(read_env_value "SECRET_KEY_BASE")
    if [ -z "$SECRET_KEY_BASE_DEFAULT" ]; then
        # 尝试生成一个随机密钥
        SECRET_KEY_BASE=$(openssl rand -hex 64 2>/dev/null || head -c 128 /dev/urandom | base64 | tr -d '\n')
        print_success "已自动生成 SECRET_KEY_BASE"
    else
        SECRET_KEY_BASE=$SECRET_KEY_BASE_DEFAULT
        print_info "使用现有的 SECRET_KEY_BASE"
    fi

    echo ""
    echo "=========================================="
    echo "🔐 Docker 镜像仓库认证"
    echo "=========================================="
    echo ""

    # Docker 镜像仓库配置（始终显示，便于查看或修改；按回车保留当前值）
    REGISTRY_SERVER="registry.devops.tanmer.com"
    print_info "Docker 镜像仓库地址: ${REGISTRY_SERVER} (固定)"

    REGISTRY_USERNAME_DEFAULT=$(read_env_value "REGISTRY_USERNAME")
    REGISTRY_PASSWORD_DEFAULT=$(read_env_value "REGISTRY_PASSWORD")
    # 从 IMAGE_NAME 中提取用户名作为默认（如果存在）
    IMAGE_NAME_DEFAULT=$(read_env_value "IMAGE_NAME")
    if [ -z "$REGISTRY_USERNAME_DEFAULT" ] && [ -n "$IMAGE_NAME_DEFAULT" ]; then
        if echo "$IMAGE_NAME_DEFAULT" | grep -q "^${REGISTRY_SERVER}/"; then
            NAMESPACE_PART=$(echo "$IMAGE_NAME_DEFAULT" | sed "s|^${REGISTRY_SERVER}/||" | cut -d'/' -f1)
            [ -n "$NAMESPACE_PART" ] && [ "$NAMESPACE_PART" != "$IMAGE_NAME_DEFAULT" ] && REGISTRY_USERNAME_DEFAULT=$NAMESPACE_PART
        fi
    fi

    REGISTRY_USERNAME=$(prompt_config "REGISTRY_USERNAME" "Docker 镜像仓库用户名（账户名）")
    REGISTRY_PASSWORD=$(prompt_config_secret "REGISTRY_PASSWORD" "Docker 镜像仓库密码")

    # 配置镜像名称和标签
    echo ""
    IMAGE_NAME=$(prompt_config "IMAGE_NAME" "Docker 镜像完整路径（如：registry.devops.tanmer.com/your-account/baklib）")
    IMAGE_TAG=$(prompt_config "IMAGE_TAG" "Docker 镜像标签（如：v1.31.0）")
fi

echo ""
echo "=========================================="
echo "💾 保存配置到 .env 文件"
echo "=========================================="
echo ""

# 更新基础配置
update_env_file "MAIN_DOMAIN" "$MAIN_DOMAIN"
update_env_file "SAAS_DOMAIN_SUFFIX" "$SAAS_DOMAIN_SUFFIX"
update_env_file "FREE_DOMAIN_SUFFIX" "$FREE_DOMAIN_SUFFIX"
update_env_file "CNAME_DNS_SUFFIX" "$CNAME_DNS_SUFFIX"

# 如果是本地试用环境，更新相关配置
if [ "$IS_LOCAL_TRIAL" = "true" ]; then
    update_env_file "SHOW_VERIFICATION_CODE" "$SHOW_VERIFICATION_CODE"
    update_env_file "INGRESS_PROTOCOL" "$INGRESS_PROTOCOL"
    update_env_file "INGRESS_PORT" "$INGRESS_PORT"
fi

# 更新 HTTPS 配置
if [ -n "$MAIN_DOMAIN_CERT_RESOLVER" ]; then
    update_env_file "MAIN_DOMAIN_CERT_RESOLVER" "$MAIN_DOMAIN_CERT_RESOLVER"
    update_env_file "SAAS_DOMAIN_CERT_RESOLVER" "$SAAS_DOMAIN_CERT_RESOLVER"
    update_env_file "API_DOMAIN_CERT_RESOLVER" "$API_DOMAIN_CERT_RESOLVER"
    update_env_file "FREE_DOMAIN_CERT_RESOLVER" "$FREE_DOMAIN_CERT_RESOLVER"
else
    # 删除 HTTPS 配置
    if sed --version >/dev/null 2>&1; then
        sed -i '/^MAIN_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '/^SAAS_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '/^API_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '/^FREE_DOMAIN_CERT_RESOLVER=/d' .env
    else
        sed -i '' '/^MAIN_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '' '/^SAAS_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '' '/^API_DOMAIN_CERT_RESOLVER=/d' .env
        sed -i '' '/^FREE_DOMAIN_CERT_RESOLVER=/d' .env
    fi
fi

# 更新 DNS 配置
if [ -n "$DNS_ALIYUN_ACCESS_KEY" ]; then
    update_env_file "DNS_ALIYUN_ACCESS_KEY" "$DNS_ALIYUN_ACCESS_KEY"
    update_env_file "DNS_ALIYUN_SECRET_KEY" "$DNS_ALIYUN_SECRET_KEY"
fi

# 更新 ACME 邮箱
if [ -n "$ACME_EMAIL" ]; then
    update_env_file "ACME_EMAIL" "$ACME_EMAIL"
fi

# 更新存储配置
update_env_file "STORAGE_SAAS_DEFAULT_SERVICE" "$STORAGE_SAAS_DEFAULT_SERVICE"

case "$STORAGE_SAAS_DEFAULT_SERVICE" in
    qinium)
        update_env_file "STORAGE_QINIU_ACCESS_KEY" "$STORAGE_QINIU_ACCESS_KEY"
        update_env_file "STORAGE_QINIU_SECRET_KEY" "$STORAGE_QINIU_SECRET_KEY"
        update_env_file "STORAGE_QINIU_BUCKET" "$STORAGE_QINIU_BUCKET"
        update_env_file "STORAGE_QINIU_PROTOCOL" "$STORAGE_QINIU_PROTOCOL"
        update_env_file "STORAGE_QINIU_DOMAIN" "$STORAGE_QINIU_DOMAIN"
        ;;
    aliyun)
        update_env_file "STORAGE_ALIIYUN_ACCESS_KEY" "$STORAGE_ALIIYUN_ACCESS_KEY"
        update_env_file "STORAGE_ALIIYUN_SECRET_KEY" "$STORAGE_ALIIYUN_SECRET_KEY"
        update_env_file "STORAGE_ALIIYUN_BUCKET" "$STORAGE_ALIIYUN_BUCKET"
        [ -n "$STORAGE_ALIIYUN_ENDPOINT" ] && update_env_file "STORAGE_ALIIYUN_ENDPOINT" "$STORAGE_ALIIYUN_ENDPOINT"
        [ -n "$STORAGE_ALIIYUN_CDN_HOST" ] && update_env_file "STORAGE_ALIIYUN_CDN_HOST" "$STORAGE_ALIIYUN_CDN_HOST"
        [ -n "$STORAGE_ALIIYUN_CDN_KEY" ] && update_env_file "STORAGE_ALIIYUN_CDN_KEY" "$STORAGE_ALIIYUN_CDN_KEY"
        update_env_file "STORAGE_ALIIYUN_PUBLIC" "$STORAGE_ALIIYUN_PUBLIC"
        ;;
    amazon)
        update_env_file "STORAGE_AWS_ACCESS_KEY" "$STORAGE_AWS_ACCESS_KEY"
        update_env_file "STORAGE_AWS_SECRET_KEY" "$STORAGE_AWS_SECRET_KEY"
        update_env_file "STORAGE_AWS_BUCKET" "$STORAGE_AWS_BUCKET"
        update_env_file "STORAGE_AWS_REGION" "$STORAGE_AWS_REGION"
        update_env_file "STORAGE_AWS_PUBLIC" "$STORAGE_AWS_PUBLIC"
        update_env_file "STORAGE_AWS_EXPIRES_IN" "$STORAGE_AWS_EXPIRES_IN"
        [ -n "$STORAGE_AWS_CDN_HOST" ] && update_env_file "STORAGE_AWS_CDN_HOST" "$STORAGE_AWS_CDN_HOST"
        [ -n "$STORAGE_AWS_CDN_PUBLIC_KEY_ID" ] && update_env_file "STORAGE_AWS_CDN_PUBLIC_KEY_ID" "$STORAGE_AWS_CDN_PUBLIC_KEY_ID"
        [ -n "$STORAGE_AWS_CDN_PRIVATE_KEY_BASE64" ] && update_env_file "STORAGE_AWS_CDN_PRIVATE_KEY_BASE64" "$STORAGE_AWS_CDN_PRIVATE_KEY_BASE64"
        ;;
esac

# 更新其他配置
update_env_file "EXTERNAL_IP" "$EXTERNAL_IP"
update_env_file "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
update_env_file "ETCD_ROOT_PASSWORD" "$ETCD_ROOT_PASSWORD"
update_env_file "SECRET_KEY_BASE" "$SECRET_KEY_BASE"
update_env_file "ADMIN_PHONE" "$ADMIN_PHONE"

# 更新 Docker 镜像仓库配置
if [ -n "$REGISTRY_USERNAME" ]; then
    update_env_file "REGISTRY_USERNAME" "$REGISTRY_USERNAME"
fi
if [ -n "$REGISTRY_PASSWORD" ]; then
    update_env_file "REGISTRY_PASSWORD" "$REGISTRY_PASSWORD"
fi
if [ -n "$IMAGE_NAME" ]; then
    update_env_file "IMAGE_NAME" "$IMAGE_NAME"
fi
if [ -n "$IMAGE_TAG" ]; then
    update_env_file "IMAGE_TAG" "$IMAGE_TAG"
fi

print_success "配置已保存到 .env 文件"
echo ""

# 更新 Traefik 配置文件
echo "=========================================="
echo "🔧 更新 Traefik 配置文件"
echo "=========================================="
echo ""

update_traefik_configs() {
    local enable_https=$1
    local main_domain=$2
    local etcd_password=$3
    local acme_email=$4
    local cert_resolver=$5

    # 检测 sed 命令（macOS 使用 BSD sed，需要 -i ''；Linux 使用 GNU sed，只需要 -i）
    if sed --version >/dev/null 2>&1; then
        # GNU sed (Linux)
        SED_INPLACE() {
            sed -i "$@"
        }
    else
        # BSD sed (macOS)
        SED_INPLACE() {
            sed -i '' "$@"
        }
    fi

    # 更新 traefik.yml
    if [ -f "traefik/etc/traefik.yml" ]; then
        print_info "更新 traefik/etc/traefik.yml..."

        # 更新 ETCD 认证配置
        # 如果提供了密码，更新密码；否则注释掉 username 和 password（etcd 认证未启用）
        if [ -n "$etcd_password" ]; then
            # 更新密码
            SED_INPLACE "s|password: .*|password: $etcd_password|" traefik/etc/traefik.yml
            # 确保 username 未被注释
            SED_INPLACE "s|#username: root|username: root|" traefik/etc/traefik.yml
            SED_INPLACE "s|#  username: root|username: root|" traefik/etc/traefik.yml
        else
            # 如果没有密码，注释掉 username 和 password（etcd 认证未启用）
            SED_INPLACE "s|^    username: root|    #username: root|" traefik/etc/traefik.yml
            SED_INPLACE "s|^    password: .*|    #password: your_etcd_root_password_here|" traefik/etc/traefik.yml
        fi

        # 根据存储类型设置 readTimeout
        # 本地存储时设置为 20 分钟（1200 秒），云存储时保持 5 分钟（300 秒）
        STORAGE_TYPE=$(read_env_value "STORAGE_SAAS_DEFAULT_SERVICE")
        STORAGE_TYPE=${STORAGE_TYPE:-local}

        if [ "$STORAGE_TYPE" = "local" ]; then
            # 本地存储：设置为 20 分钟
            print_info "检测到本地存储，设置 readTimeout 为 20 分钟..."
            SED_INPLACE 's|readTimeout: [0-9]*|readTimeout: 1200|' traefik/etc/traefik.yml
        else
            # 云存储：设置为 5 分钟
            print_info "检测到云存储 ($STORAGE_TYPE)，设置 readTimeout 为 5 分钟..."
            SED_INPLACE 's|readTimeout: [0-9]*|readTimeout: 300|' traefik/etc/traefik.yml
        fi

        # 根据是否开启 HTTPS，注释或取消注释 certificatesResolvers
        if [ "$enable_https" = "y" ] || [ "$enable_https" = "yes" ]; then
            # 取消注释 certificatesResolvers（如果被注释了）
            # 处理格式：`#certificatesResolvers:` 或 `#  http01:`（# 在行首，后面是缩进）
            SED_INPLACE '/^#certificatesResolvers:/s/^#//' traefik/etc/traefik.yml
            # 匹配格式：`#  http01:` -> `  http01:`（去掉行首的 #，保留缩进）
            SED_INPLACE '/^#[[:space:]]\{2\}http01:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{4\}acme:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{6\}email:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{6\}storage:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{6\}httpChallenge:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{8\}entryPoint:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{2\}alidns:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{6\}dnsChallenge:/s/^#//' traefik/etc/traefik.yml
            SED_INPLACE '/^#[[:space:]]\{8\}provider:/s/^#//' traefik/etc/traefik.yml
            # 也处理旧格式（兼容性）：`  #  http01:` -> `  http01:`
            SED_INPLACE '/^[[:space:]]\{2\}#[[:space:]]*http01:/s/^\([[:space:]]\{2\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{4\}#[[:space:]]*acme:/s/^\([[:space:]]\{4\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}#[[:space:]]*email:/s/^\([[:space:]]\{6\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}#[[:space:]]*storage:/s/^\([[:space:]]\{6\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}#[[:space:]]*httpChallenge:/s/^\([[:space:]]\{6\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{8\}#[[:space:]]*entryPoint:/s/^\([[:space:]]\{8\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{2\}#[[:space:]]*alidns:/s/^\([[:space:]]\{2\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}#[[:space:]]*dnsChallenge:/s/^\([[:space:]]\{6\}\)# */\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{8\}#[[:space:]]*provider:/s/^\([[:space:]]\{8\}\)# */\1/' traefik/etc/traefik.yml

            # 更新 ACME 邮箱
            if [ -n "$acme_email" ]; then
                SED_INPLACE "s|email: 'acme-your-email@[^']*'|email: '$acme_email'|g" traefik/etc/traefik.yml
            fi
        else
            # 注释掉 certificatesResolvers（如果没有被注释）
            # 在行首添加 #，保持原有缩进对齐
            SED_INPLACE '/^certificatesResolvers:/s/^/#/' traefik/etc/traefik.yml
            # 对于有缩进的行，在行首（缩进之前）添加 #，保留原有缩进
            SED_INPLACE '/^[[:space:]]\{2\}http01:/s/^\([[:space:]]\{2\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{4\}acme:/s/^\([[:space:]]\{4\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}email:/s/^\([[:space:]]\{6\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}storage:/s/^\([[:space:]]\{6\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}httpChallenge:/s/^\([[:space:]]\{6\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{8\}entryPoint:/s/^\([[:space:]]\{8\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{2\}alidns:/s/^\([[:space:]]\{2\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{6\}dnsChallenge:/s/^\([[:space:]]\{6\}\)/#\1/' traefik/etc/traefik.yml
            SED_INPLACE '/^[[:space:]]\{8\}provider:/s/^\([[:space:]]\{8\}\)/#\1/' traefik/etc/traefik.yml
        fi

        print_success "已更新 traefik/etc/traefik.yml"
    else
        print_warning "traefik/etc/traefik.yml 文件不存在，跳过更新"
    fi

    # 更新 common.yml - HTTP 到 HTTPS 重定向
    if [ -f "traefik/etc/dynamic/common.yml" ]; then
        print_info "更新 traefik/etc/dynamic/common.yml..."

        # 先清理掉第一条被注释的 rule（如果存在），避免重复的 rule
        # 删除缩进不对的被注释的 rule 行
        SED_INPLACE '/^       # rule:/d' traefik/etc/dynamic/common.yml
        SED_INPLACE '/^      # rule:.*ASSET_CDN_HOST/d' traefik/etc/dynamic/common.yml

        if [ "$enable_https" = "y" ] || [ "$enable_https" = "yes" ]; then
            # 检查 http-to-https 路由是否存在
            if ! grep -q "http-to-https:" traefik/etc/dynamic/common.yml; then
                # 路由不存在，需要重新添加（在 routers: 后添加）
                python3 << 'PYTHON_SCRIPT'
import re
import sys

file_path = "traefik/etc/dynamic/common.yml"
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    routers_section_found = False
    routers_section_inserted = False

    for i, line in enumerate(lines):
        # 检查是否到达 routers: 部分
        if re.match(r'^\s*routers:\s*$', line):
            routers_section_found = True
            new_lines.append(line)
            # 检查下一行是否是 middlewares:，如果是，说明 routers 部分是空的，需要插入路由
            if i + 1 < len(lines) and re.match(r'^\s*middlewares:\s*$', lines[i + 1]):
                new_lines.append("    http-to-https:\n")
                new_lines.append("      # rule: \"HostRegexp(`{host:.+}`) && !Host(`<%= URI(ENV['ASSET_CDN_HOST']).host %>`)\"\n")
                new_lines.append("      rule: \"HostRegexp(`.+\\\\.[a-z0-9]+$`)\"\n")
                new_lines.append("      priority: 2\n")
                new_lines.append("      entryPoints: \"http\"\n")
                new_lines.append("      service: \"noop@internal\"\n")
                new_lines.append("      middlewares: \"httpToHttpsRedirect\"\n")
                routers_section_inserted = True
            # 不要 continue，继续处理后续行

        # 如果 routers 部分存在但没有路由，在 middlewares: 之前插入
        if routers_section_found and not routers_section_inserted and re.match(r'^\s*middlewares:\s*$', line):
            new_lines.append("    http-to-https:\n")
            new_lines.append("      # rule: \"HostRegexp(`{host:.+}`) && !Host(`<%= URI(ENV['ASSET_CDN_HOST']).host %>`)\"\n")
            new_lines.append("      rule: \"HostRegexp(`.+\\\\.[a-z0-9]+$`)\"\n")
            new_lines.append("      priority: 2\n")
            new_lines.append("      entryPoints: \"http\"\n")
            new_lines.append("      service: \"noop@internal\"\n")
            new_lines.append("      middlewares: \"httpToHttpsRedirect\"\n")
            routers_section_inserted = True

        new_lines.append(line)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
            else
                # 路由存在，取消注释（如果被注释了）
                SED_INPLACE '/^    #http-to-https:/s/^    #/    /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      #rule:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      # rule:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      #priority:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      # priority:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      #entryPoints:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      # entryPoints:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      #service:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      # service:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      #middlewares:/s/^      #/      /' traefik/etc/dynamic/common.yml
                SED_INPLACE '/^      # middlewares:/s/^      #/      /' traefik/etc/dynamic/common.yml
            fi
        else
            # HTTP 模式下保留 http-to-https 路由（不删除，允许保留）
            # 即使没有启用 HTTPS，这个路由也可以保留，不会造成问题
            print_info "HTTP 模式：保留 http-to-https 路由配置"
        fi

        # 根据存储类型设置请求体大小限制
        # 本地存储时设置为 10GB (10737418240 字节)，云存储时限制为 100MB (104857600 字节)
        STORAGE_TYPE=$(read_env_value "STORAGE_SAAS_DEFAULT_SERVICE")
        STORAGE_TYPE=${STORAGE_TYPE:-local}

        if [ "$STORAGE_TYPE" = "local" ]; then
            # 本地存储：设置为 10GB
            print_info "检测到本地存储，设置请求体大小限制为 10GB..."
            if ! grep -q "^        maxRequestBodyBytes:" traefik/etc/dynamic/common.yml; then
                # 如果不存在，在 buffering: 下添加
                SED_INPLACE '/^      buffering:/a\        maxRequestBodyBytes: 10737418240' traefik/etc/dynamic/common.yml
            else
                # 如果存在，确保值为 10737418240
                SED_INPLACE 's/^        maxRequestBodyBytes:.*/        maxRequestBodyBytes: 10737418240/' traefik/etc/dynamic/common.yml
            fi
        else
            # 云存储：确保限制为 100MB（如果不存在则添加）
            print_info "检测到云存储 ($STORAGE_TYPE)，设置请求体大小限制为 100MB..."
            if ! grep -q "^        maxRequestBodyBytes:" traefik/etc/dynamic/common.yml; then
                # 如果不存在，在 buffering: 下添加
                SED_INPLACE '/^      buffering:/a\        maxRequestBodyBytes: 104857600' traefik/etc/dynamic/common.yml
            else
                # 如果存在，确保值为 104857600
                SED_INPLACE 's/^        maxRequestBodyBytes:.*/        maxRequestBodyBytes: 104857600/' traefik/etc/dynamic/common.yml
            fi
        fi

        print_success "已更新 traefik/etc/dynamic/common.yml"
    else
        print_warning "traefik/etc/dynamic/common.yml 文件不存在，跳过更新"
    fi

    # 更新 traefik-dashboard.yml - 域名和 HTTPS 配置
    # 注意：此函数只更新域名、entryPoints 和 TLS 配置，不会修改 basicAuth 配置
    if [ -f "traefik/etc/dynamic/traefik-dashboard.yml" ]; then
        print_info "更新 traefik/etc/dynamic/traefik-dashboard.yml..."

        if [ -n "$main_domain" ]; then
            # 更新 Dashboard 域名（只更新路由规则中的域名，不修改其他配置）
            local dashboard_domain="traefik-777.${main_domain}"
            # 更新 rule: Host() 中的域名（匹配任何现有域名）
            # 使用单引号包裹模式，避免反引号被 shell 解释为命令替换
            SED_INPLACE 's|rule: Host(`traefik-777\.[^`]*`)|rule: Host(`'"${dashboard_domain}"'`)|' traefik/etc/dynamic/traefik-dashboard.yml
            # 更新 TLS 配置中的域名
            SED_INPLACE "s|main: '[^']*'|main: '${main_domain}'|" traefik/etc/dynamic/traefik-dashboard.yml
            SED_INPLACE "s|- '\*\.[^']*'|- '\*.${main_domain}'|" traefik/etc/dynamic/traefik-dashboard.yml

            # 根据是否开启 HTTPS，更新 entryPoints 和 TLS 配置
            if [ "$enable_https" = "y" ] || [ "$enable_https" = "yes" ]; then
                # 使用 HTTPS（只匹配完整的 entryPoints: http，不匹配 https 中的 http）
                SED_INPLACE "s|entryPoints: http\$|entryPoints: https|" traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE "s|entryPoints: httpss\$|entryPoints: https|" traefik/etc/dynamic/traefik-dashboard.yml
                # 取消注释 TLS 配置（如果被注释了）
                SED_INPLACE '/^      #tls:/s/^      #/      /' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        #certResolver:/s/^        #/        /' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        #domains:/s/^        #/        /' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        #- main:/s/^        #/        /' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^          #sans:/s/^          #/          /' traefik/etc/dynamic/traefik-dashboard.yml
                # 只匹配 TLS 配置中的通配符域名行（包含 *.），避免匹配 basicAuth 的用户行
                SED_INPLACE '/^          #- .*\*\./s/^          #/          /' traefik/etc/dynamic/traefik-dashboard.yml

                # 更新证书解析器（从任何值更新到目标值）
                if [ -n "$cert_resolver" ]; then
                    # 匹配任何证书解析器值并替换
                    SED_INPLACE "s|certResolver: [a-zA-Z0-9]*|certResolver: ${cert_resolver}|" traefik/etc/dynamic/traefik-dashboard.yml
                fi
            else
                # 使用 HTTP（只匹配完整的 entryPoints: https，不匹配 http 中的 http）
                SED_INPLACE "s|entryPoints: https\$|entryPoints: http|" traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE "s|entryPoints: httpss\$|entryPoints: http|" traefik/etc/dynamic/traefik-dashboard.yml
                # 注释掉 TLS 配置（如果没有被注释）
                SED_INPLACE '/^      tls:/s/^      /      #/' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        certResolver:/s/^        /        #/' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        domains:/s/^        /        #/' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^        - main:/s/^        /        #/' traefik/etc/dynamic/traefik-dashboard.yml
                SED_INPLACE '/^          sans:/s/^          /          #/' traefik/etc/dynamic/traefik-dashboard.yml
                # 只匹配 TLS 配置中的通配符域名行（包含 *.），避免匹配 basicAuth 的用户行
                SED_INPLACE '/^          - .*\*\./s/^          /          #/' traefik/etc/dynamic/traefik-dashboard.yml
            fi

            print_success "已更新 traefik/etc/dynamic/traefik-dashboard.yml"
        else
            print_warning "主域名为空，跳过 Dashboard 域名更新"
        fi
    else
        print_warning "traefik/etc/dynamic/traefik-dashboard.yml 文件不存在，跳过更新"
    fi

    # 更新 docker-compose.yml - Traefik 路由配置
    if [ -f "docker-compose.yml" ]; then
        print_info "更新 docker-compose.yml 中的 Traefik 路由配置..."

        # 定义路由名称数组
        local routers=("baklib-web" "baklib-saas" "baklib-api" "baklib-trial")

        if [ "$enable_https" = "y" ] || [ "$enable_https" = "yes" ]; then
            # 启用 HTTPS：使用 https entryPoint 和 TLS
            for router in "${routers[@]}"; do
                # 更新 entryPoints 为 https
                SED_INPLACE "s|traefik\.http\.routers\.${router}\.entryPoints: \"http\"|traefik.http.routers.${router}.entryPoints: \"https\"|" docker-compose.yml

                # 检查 TLS 配置是否存在（包括注释的行）
                if grep -q "traefik\.http\.routers\.${router}\.tls:" docker-compose.yml; then
                    # 如果存在但被注释，取消注释（处理各种可能的注释格式）
                    # 匹配：      #traefik.http.routers.xxx.tls: 或 #traefik.http.routers.xxx.tls:
                    SED_INPLACE "/traefik\.http\.routers\.${router}\.tls:/s/^[[:space:]]*#//" docker-compose.yml
                    # 确保值为 true（无论之前是什么值）
                    SED_INPLACE "s|traefik\.http\.routers\.${router}\.tls: \".*\"|traefik.http.routers.${router}.tls: \"true\"|" docker-compose.yml
                else
                    # 如果不存在，在 middlewares 行后添加（使用 Python 确保缩进正确）
                    python3 << PYTHON_SCRIPT
import re
import sys

file_path = "docker-compose.yml"
router_name = "${router}"

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    tls_added = False
    pattern = re.compile(rf'traefik\.http\.routers\.{re.escape(router_name)}\.middlewares:')

    for i, line in enumerate(lines):
        new_lines.append(line)
        # 如果匹配到 middlewares 行，且下一行不是 TLS 配置，则添加 TLS 配置
        if pattern.search(line) and not tls_added:
            # 获取当前行的缩进
            indent = re.match(r'^(\s*)', line).group(1)
            # 检查下一行是否已经是 TLS 配置
            if i + 1 < len(lines) and f'traefik.http.routers.{router_name}.tls:' not in lines[i + 1]:
                new_lines.append(f'{indent}traefik.http.routers.{router_name}.tls: "true"\n')
                tls_added = True

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
                fi
            done
        else
            # 禁用 HTTPS：使用 http entryPoint 并注释 TLS
            for router in "${routers[@]}"; do
                # 更新 entryPoints 为 http
                SED_INPLACE "s|traefik\.http\.routers\.${router}\.entryPoints: \"https\"|traefik.http.routers.${router}.entryPoints: \"http\"|" docker-compose.yml

                # 注释掉 TLS 配置（如果还没有被注释）
                # 匹配未注释的行，在行首添加 #（保留原有缩进）
                SED_INPLACE "/^[[:space:]]*traefik\.http\.routers\.${router}\.tls:/s/^\([[:space:]]*\)/\1#/" docker-compose.yml
            done
        fi

        print_success "已更新 docker-compose.yml 中的 Traefik 路由配置"
    else
        print_warning "docker-compose.yml 文件不存在，跳过更新"
    fi
}

# 调用更新函数
update_traefik_configs "$ENABLE_HTTPS" "$MAIN_DOMAIN" "$ETCD_ROOT_PASSWORD" "$ACME_EMAIL" "$MAIN_DOMAIN_CERT_RESOLVER"

print_success "Traefik 配置文件更新完成"
echo ""

# 检查必要的文件
print_info "检查必要的文件..."

# 检查 product.pem
if [ ! -f "product.pem" ]; then
    print_warning "product.pem 文件不存在"
    print_info "如果不需要产品证书，可以创建一个空文件："
    echo "  touch product.pem"
    echo ""
fi

# 检查 Traefik 配置文件
if [ ! -f "traefik/etc/traefik.yml" ]; then
    print_warning "Traefik 配置文件不存在"
    print_info "请确保 traefik/etc/traefik.yml 文件存在"
fi
echo ""

# 验证 .env 文件语法
print_info "验证 .env 文件语法..."
if ! validate_env_file ".env"; then
    print_error ".env 文件有语法错误，请修复后再继续"
    echo ""
    echo "常见问题："
    echo "  1. 未匹配的引号（单引号或双引号）"
    echo "  2. 变量名中包含非法字符"
    echo "  3. 特殊字符未正确转义"
    echo ""
    echo "请检查 .env 文件，特别是错误提示的行号附近"
    exit 1
fi
print_success ".env 文件语法检查通过"
echo ""

