#!/bin/bash

# 重启服务脚本

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🔄 重启 Baklib Docker Compose 服务"
echo "=========================================="
echo ""

# 检查 .env 文件
if [ ! -f ".env" ]; then
    print_error ".env 文件不存在，请先运行配置脚本："
    echo "  ./baklib config"
    exit 1
fi

# 检查 Docker 环境
check_command docker
check_docker_running

COMPOSE_CMD=$(get_compose_cmd)

# 重启服务
print_info "重启服务..."
if ! $COMPOSE_CMD restart; then
    print_error "重启服务失败！请检查日志："
    echo "  $COMPOSE_CMD logs"
    exit 1
fi

echo ""
print_info "等待服务启动..."
sleep 5

# 显示服务状态
echo ""
echo "=========================================="
echo "📊 服务状态"
echo "=========================================="
echo ""
$COMPOSE_CMD ps
echo ""

print_success "服务重启完成！"
echo ""

