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

# 3. Docker 镜像仓库登录（在拉取镜像之前）
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

# 4. 拉取镜像
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
echo "  ./start.sh             - 启动服务"
echo "  ./import-themes.sh     - 导入主题模版到数据库（首次安装必选，需要服务器已正常启动后执行）"
echo "  ./stop.sh              - 停止服务"
echo ""
