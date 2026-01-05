#!/bin/bash

# 停止服务脚本

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🛑 停止 Baklib Docker Compose 服务"
echo "=========================================="
echo ""

# 检查 Docker 环境
check_command docker
check_docker_running

COMPOSE_CMD=$(get_compose_cmd)

# 检查是否有服务在运行
if ! $COMPOSE_CMD ps 2>/dev/null | grep -q "Up"; then
    print_info "没有运行中的服务"
    exit 0
fi

# 显示当前运行的服务
echo "当前运行的服务："
$COMPOSE_CMD ps
echo ""

read -p "确认要停止所有服务吗？(y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    print_info "操作已取消"
    exit 0
fi

# 停止服务
print_info "停止服务..."
if ! $COMPOSE_CMD stop; then
    print_error "停止服务失败"
    exit 1
fi

echo ""
print_success "服务已停止"
echo ""

# 显示服务状态
echo "服务状态："
$COMPOSE_CMD ps
echo ""

