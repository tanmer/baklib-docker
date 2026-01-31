#!/usr/bin/env bash
# 维护者用：从 Dockerfile.cli 构建多平台 CLI 镜像（amd64 + arm64）并推送到仓库
# 用法: ./scripts/build-and-push-cli.sh [镜像地址]
#   例如: ./scripts/build-and-push-cli.sh registry.devops.tanmer.com/library/baklib-cli:latest
# 未传参数时使用环境变量 BAKLIB_CLI_IMAGE；若都未设置则报错退出

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

TARGET_IMAGE="${1:-${BAKLIB_CLI_IMAGE:-}}"
if [ -z "$TARGET_IMAGE" ]; then
  echo "用法: $0 <镜像地址>"
  echo "  或设置环境变量 BAKLIB_CLI_IMAGE 后执行 $0"
  echo "示例: $0 registry.devops.tanmer.com/library/baklib-cli:latest"
  exit 1
fi

# 使用 buildx 多平台构建（amd64 + arm64）
BUILDER_NAME="baklib-cli-multi"
if ! docker buildx inspect "$BUILDER_NAME" >/dev/null 2>&1; then
  echo "创建多平台 builder: $BUILDER_NAME"
  docker buildx create --name "$BUILDER_NAME" --driver docker-container --use
fi
docker buildx use "$BUILDER_NAME" >/dev/null 2>&1
docker buildx inspect --bootstrap >/dev/null 2>&1

echo "构建多平台 CLI 镜像（linux/amd64, linux/arm64）: $TARGET_IMAGE"
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -f Dockerfile.cli \
  -t "$TARGET_IMAGE" \
  --push \
  .
echo "完成。"
