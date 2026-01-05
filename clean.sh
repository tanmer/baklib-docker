#!/bin/bash

# Docker Compose 清理脚本
# 用于清理所有容器、网络和数据卷

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 生成随机验证码（4位数字）
generate_verification_code() {
    echo $(($RANDOM % 9000 + 1000))
}

# 验证用户输入
verify_code() {
    local correct_code=$1
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        echo ""
        read -p "请输入验证码以确认清理操作: " user_input

        if [ "$user_input" = "$correct_code" ]; then
            return 0
        else
            attempt=$((attempt + 1))
            if [ $attempt -le $max_attempts ]; then
                echo "❌ 验证码错误！还有 $((max_attempts - attempt + 1)) 次机会"
            else
                echo "❌ 验证码错误次数过多，操作已取消！"
                return 1
            fi
        fi
    done

    return 1
}

echo "=========================================="
echo "⚠️  警告：此操作将删除所有容器、网络和数据卷！"
echo "=========================================="
echo ""
echo "⚠️  此操作不可逆，请确保已备份重要数据！"
echo ""

# 生成并显示验证码
VERIFICATION_CODE=$(generate_verification_code)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "验证码: $VERIFICATION_CODE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 验证用户输入
if ! verify_code "$VERIFICATION_CODE"; then
    echo ""
    echo "操作已取消，未执行任何清理操作。"
    exit 1
fi

echo ""
echo "✅ 验证通过！"
echo ""
echo "=========================================="
echo "开始清理 Docker Compose 资源..."
echo "=========================================="
echo ""

# 验证通过后，启用严格错误检查
set -e

# 检查 docker compose 是否可用
if ! command -v docker &> /dev/null; then
    echo "错误: 未找到 docker 命令"
    exit 1
fi

# 显示当前状态
echo "当前运行的服务:"
docker compose ps 2>/dev/null || echo "  无运行的服务"
echo ""

echo "当前数据卷:"
docker compose volumes 2>/dev/null || echo "  无数据卷"
echo ""

# 停止所有服务
echo "1. 停止所有服务..."
docker compose stop 2>/dev/null || echo "  无需要停止的服务"
echo ""

# 删除所有容器
echo "2. 删除所有容器..."
docker compose rm -f 2>/dev/null || echo "  无需要删除的容器"
echo ""

# 删除所有资源（容器、网络、卷）
echo "3. 删除所有资源（容器、网络、数据卷）..."
docker compose down -v --remove-orphans 2>/dev/null || echo "  无需要删除的资源"
echo ""

# 验证清理结果
echo "=========================================="
echo "清理完成！验证结果："
echo "=========================================="
echo ""

echo "剩余容器:"
if docker compose ps 2>/dev/null | grep -q "NAME"; then
    docker compose ps
else
    echo "  ✓ 无剩余容器"
fi
echo ""

echo "剩余数据卷:"
if docker compose volumes 2>/dev/null | grep -q "VOLUME NAME"; then
    docker compose volumes
else
    echo "  ✓ 无剩余数据卷"
fi
echo ""

echo "剩余网络:"
if docker network ls 2>/dev/null | grep -q "baklib"; then
    docker network ls | grep baklib
else
    echo "  ✓ 无剩余网络"
fi
echo ""

echo "=========================================="
echo "清理完成！"
echo "=========================================="

