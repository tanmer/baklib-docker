#!/bin/bash

# Docker Compose 安装脚本
# 用于初始化环境并安装所有服务

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🚀 Baklib Docker Compose 安装脚本"
echo "=========================================="
echo ""

# 1. 检查环境
print_info "检查环境..."
check_command docker
# 检查 docker compose 是否可用（新版本使用 docker compose，旧版本使用 docker-compose）
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    print_error "未找到 docker compose 命令，请先安装 Docker Compose"
    exit 1
fi
check_docker_running
print_success "环境检查通过"
echo ""

# 2. 运行配置脚本
print_info "运行配置脚本..."
if [ -f "config.sh" ]; then
    bash config.sh
    if [ $? -ne 0 ]; then
        print_error "配置失败，安装已取消"
        exit 1
    fi
else
    print_error "找不到 config.sh 文件"
    exit 1
fi
echo ""

# 3. 创建必要的目录
print_info "创建必要的目录..."
directories=(
    "logs/postgresql"
    "logs/traefik"
    "traefik/etc/dynamic"
    "storage"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "创建目录: $dir"
    else
        print_info "目录已存在: $dir"
    fi
done
echo ""

# 4. 检查必要的文件
print_info "检查必要的文件..."

# 检查 product.pem
if [ ! -f "product.pem" ]; then
    print_error "product.pem 文件不存在！"
    print_info "product.pem 是必需的配置文件，请先创建此文件"
    echo ""
    echo "如果不需要产品证书，可以创建一个空文件："
    echo "  touch product.pem"
    echo ""
    read -p "是否现在创建空的 product.pem 文件？(y/n): " create_pem
    if [ "$create_pem" = "y" ] || [ "$create_pem" = "Y" ]; then
        touch product.pem
        print_success "已创建空的 product.pem 文件"
    else
        print_error "product.pem 文件是必需的，安装已取消"
        exit 1
    fi
fi

# 检查 Traefik 配置文件
if [ ! -f "traefik/etc/traefik.yml" ]; then
    print_warning "Traefik 配置文件不存在"
    print_info "请确保 traefik/etc/traefik.yml 文件存在"
fi
echo ""

# 5. Docker 镜像仓库登录（在拉取镜像之前）
print_info "检查 Docker 镜像仓库认证..."

# Docker 镜像仓库地址（固定）
REGISTRY_SERVER_CHECK="registry.devops.tanmer.com"

REGISTRY_USERNAME_CHECK=$(read_env_value "REGISTRY_USERNAME")
REGISTRY_PASSWORD_CHECK=$(read_env_value "REGISTRY_PASSWORD")

if [ -n "$REGISTRY_USERNAME_CHECK" ] && [ -n "$REGISTRY_PASSWORD_CHECK" ]; then
    print_info "正在登录 Docker 镜像仓库: $REGISTRY_SERVER_CHECK"
    if echo "$REGISTRY_PASSWORD_CHECK" | docker login "$REGISTRY_SERVER_CHECK" --username "$REGISTRY_USERNAME_CHECK" --password-stdin 2>/dev/null; then
        print_success "Docker 镜像仓库登录成功"
    else
        print_warning "Docker 镜像仓库登录失败，将尝试匿名拉取镜像"
        print_warning "如果镜像需要认证，拉取可能会失败"
    fi
else
    print_warning "未配置 Docker 镜像仓库认证信息（REGISTRY_USERNAME 和 REGISTRY_PASSWORD）"
    print_warning "如果镜像需要认证，拉取可能会失败"
fi
echo ""

# 6. 验证 .env 文件语法（Docker Compose 会自动读取 .env 文件）
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

# 7. 拉取镜像
print_info "拉取 Docker 镜像..."
COMPOSE_CMD=$(get_compose_cmd)

if ! $COMPOSE_CMD pull; then
    print_error "镜像拉取失败！请检查："
    echo "  1. 网络连接是否正常"
    echo "  2. Docker 镜像仓库认证是否正确（检查 .env 文件中的 REGISTRY_USERNAME 和 REGISTRY_PASSWORD）"
    echo "  3. .env 文件中的镜像配置是否正确"
    echo ""
    echo "如果需要配置认证信息，请运行："
    echo "  ./config.sh"
    exit 1
fi
print_success "镜像拉取完成"
echo ""

print_success "安装完成！"
echo ""
echo "接下来可以运行以下命令："
echo "  ./start.sh    - 启动服务"
echo "  ./restart.sh  - 重启服务"
echo "  ./stop.sh     - 停止服务"
echo "  ./debug.sh    - 启动调试容器"
echo ""
