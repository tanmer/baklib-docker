#!/bin/bash

# etcd 认证启用脚本
# 用于在 etcd 服务运行后手动启用认证

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🔐 启用 etcd 认证"
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

# 检查 etcd 服务是否运行
if ! $COMPOSE_CMD ps etcd01 2>/dev/null | grep -q "Up"; then
    print_error "etcd 服务未运行，请先启动服务："
    echo "  ./start.sh"
    exit 1
fi

# 从 .env 文件读取 ETCD_ROOT_PASSWORD
ETCD_ROOT_PASSWORD=$(read_env_value "ETCD_ROOT_PASSWORD")
if [ -z "$ETCD_ROOT_PASSWORD" ]; then
    print_error "ETCD_ROOT_PASSWORD 未设置，请在 .env 文件中设置"
    exit 1
fi

# 使用公共函数初始化 etcd 认证（第三个参数为 true 表示需要重启服务）
if init_etcd_auth "$COMPOSE_CMD" "$ETCD_ROOT_PASSWORD" "true"; then
    echo ""
    print_success "完成！"
else
    print_error "etcd 认证初始化失败"
    exit 1
fi

