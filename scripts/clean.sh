#!/bin/bash

# Docker Compose 清理脚本
# 用于清理所有容器、网络和数据卷

# 从脚本所在目录定位项目根（与 common.sh 一致，便于在 scripts/ 下运行）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 生成随机验证码（4位数字）
generate_verification_code() {
    echo $(($RANDOM % 9000 + 1000))
}

# 验证用户输入（需要连续输入3次不同的验证码）
verify_code() {
    local required_confirmations=3
    local confirmed=0

    while [ $confirmed -lt $required_confirmations ]; do
        # 每次生成新的验证码
        local current_code=$(generate_verification_code)
        
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # 根据已确认次数显示不同严重程度的警告
        if [ $confirmed -eq 0 ]; then
            echo "⚠️  第一次确认：请输入验证码以确认清理操作"
            echo "⚠️  此操作将删除所有容器、网络和数据卷！"
        elif [ $confirmed -eq 1 ]; then
            echo "⚠️  ⚠️  第二次确认：请再次输入验证码"
            echo "⚠️  ⚠️  此操作将永久删除所有数据，无法恢复！"
        else
            echo "🚨 🚨 🚨 第三次确认：请最后一次输入验证码"
            echo "🚨 🚨 🚨 这是最后一次确认，输入正确后将立即执行清理操作！"
            echo "🚨 🚨 🚨 此操作将永久删除所有容器、网络和数据卷，无法恢复！"
        fi
        
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "验证码: $current_code"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        read -p "请输入验证码: " user_input

        if [ "$user_input" = "$current_code" ]; then
            confirmed=$((confirmed + 1))
            local remaining=$((required_confirmations - confirmed))
            if [ $confirmed -lt $required_confirmations ]; then
                echo ""
                echo "✅ 验证码正确！还需要 $remaining 次确认"
                if [ $confirmed -eq 1 ]; then
                    echo "⚠️  请确保您真的想要执行此危险操作！"
                else
                    echo "🚨 这是最后一次确认，请谨慎操作！"
                fi
            fi
        else
            echo ""
            echo "❌ 验证码错误！"
            echo "⚠️  为了安全，已重置确认次数，需要重新开始确认流程"
            confirmed=0
        fi
    done

    return 0
}

echo "=========================================="
echo "⚠️  警告：此操作将删除所有容器、网络和数据卷！"
echo "=========================================="
echo ""
echo "⚠️  此操作不可逆，请确保已备份重要数据！"
echo ""
echo "⚠️  为了安全，需要连续输入3次不同的验证码才能执行清理操作"
echo ""

# 验证用户输入（每次生成新的验证码）
if ! verify_code; then
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

