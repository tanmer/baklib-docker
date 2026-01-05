#!/bin/bash

# 启动服务脚本

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🚀 启动 Baklib Docker Compose 服务"
echo "=========================================="
echo ""

# 检查 .env 文件
if [ ! -f ".env" ]; then
    print_error ".env 文件不存在，请先运行配置脚本："
    echo "  ./config.sh"
    exit 1
fi

# 检查 Docker 环境
check_command docker
check_docker_running

COMPOSE_CMD=$(get_compose_cmd)

# 检查是否已有服务在运行
if $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
    print_warning "检测到已有服务在运行"
    echo ""
    $COMPOSE_CMD ps
    echo ""
    read -p "是否重新创建并启动服务？(y/n): " recreate
    if [ "$recreate" = "y" ] || [ "$recreate" = "Y" ]; then
        print_info "停止现有服务..."
        if ! $COMPOSE_CMD down; then
            print_error "停止服务失败"
            exit 1
        fi
    else
        print_info "保持现有服务运行"
        exit 0
    fi
fi

# 启动服务
print_info "启动服务..."
if ! $COMPOSE_CMD up -d; then
    print_error "启动服务失败！请检查日志："
    echo "  $COMPOSE_CMD logs"
    exit 1
fi

echo ""
print_info "等待服务启动..."
sleep 5

# 初始化 etcd 认证（如果需要）
print_info "检查 etcd 认证状态..."
if [ -f ".env" ]; then
    # 从 .env 文件读取 ETCD_ROOT_PASSWORD
    ETCD_ROOT_PASSWORD=$(read_env_value "ETCD_ROOT_PASSWORD")
    if [ -n "$ETCD_ROOT_PASSWORD" ]; then
        # 使用公共函数初始化 etcd 认证（第三个参数为 true 表示需要重启服务）
        if ! init_etcd_auth "$COMPOSE_CMD" "$ETCD_ROOT_PASSWORD" "true"; then
            print_warning "etcd 认证初始化失败或跳过"
        fi
    else
        print_warning "ETCD_ROOT_PASSWORD 未设置，etcd 将使用无认证模式"
        print_warning "建议设置 ETCD_ROOT_PASSWORD 以提高安全性"
    fi
fi
echo ""

# 显示服务状态
echo ""
echo "=========================================="
echo "📊 服务状态"
echo "=========================================="
echo ""
$COMPOSE_CMD ps
echo ""

# 显示健康检查
print_info "检查服务健康状态..."
echo ""

services=("db" "redis" "etcd01" "etcd02" "etcd03" "web" "job" "traefik")

for service in "${services[@]}"; do
    status=$($COMPOSE_CMD ps $service 2>/dev/null | tail -n +2 | awk '{print $4}')
    if [ -n "$status" ]; then
        if echo "$status" | grep -q "healthy\|Up"; then
            print_success "$service: 运行中"
        else
            print_warning "$service: $status"
        fi
    fi
done
echo ""

print_success "服务启动完成！"
echo ""
echo "常用命令："
echo "  ./restart.sh        - 重启服务"
echo "  ./stop.sh           - 停止服务"
echo "  $COMPOSE_CMD logs -f - 查看日志"
echo "  $COMPOSE_CMD ps     - 查看状态"
echo ""

