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

# 启动服务
print_info "启动服务..."
if ! $COMPOSE_CMD up -d; then
    print_error "启动服务失败！请检查日志："
    echo "  $COMPOSE_CMD logs"
    exit 1
fi

echo ""
print_success "服务启动完成！"
echo ""
echo "常用命令："
echo "  ./restart.sh        - 重启服务"
echo "  ./stop.sh           - 停止服务"
echo "  $COMPOSE_CMD logs -f - 查看日志"
echo "  $COMPOSE_CMD ps     - 查看状态"
echo ""

