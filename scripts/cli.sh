#!/usr/bin/env bash
# 在项目根目录执行常用 docker compose 命令（等价命令见 docker-compose.cli.yml 顶部注释）
# 用法: ./scripts/cli.sh <config|install|start|stop|restart|uninstall|clean|import-themes> [参数...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
CLI_FILE="docker-compose.cli.yml"
COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$ROOT")}"

usage() {
  echo "用法: $0 <子命令> [参数...]"
  echo ""
  echo "  config          交互配置 .env（rake config）"
  echo "  install         安装准备（rake install）"
  echo "  start           启动主栈（docker compose up -d）"
  echo "  stop            停止主栈"
  echo "  restart         重启主栈"
  echo "  uninstall       移除容器，保留数据卷"
  echo "  clean           彻底清理（需三次确认）"
  echo "  import-themes   导入主题（可选 --skip-clone、--clone-only）"
  echo ""
  echo "环境变量 COMPOSE_PROJECT_NAME 可覆盖项目名（默认: 当前目录名）"
}

case "${1:-}" in
  config)
    shift
    exec docker compose -f "$CLI_FILE" run --rm config "$@"
    ;;
  install)
    export COMPOSE_PROJECT_NAME
    export HOST_PROJECT_ROOT="$ROOT"
    shift
    exec docker compose -f "$CLI_FILE" run --rm -e COMPOSE_PROJECT_NAME -e HOST_PROJECT_ROOT install "$@"
    ;;
  start)
    if [ ! -f docker-compose.yml ]; then
      echo "未找到 docker-compose.yml。请先执行: $0 config"
      exit 1
    fi
    shift
    exec docker compose up -d "$@"
    ;;
  stop)
    shift
    exec docker compose stop "$@"
    ;;
  restart)
    shift
    exec docker compose restart "$@"
    ;;
  uninstall)
    export COMPOSE_PROJECT_NAME
    shift
    exec docker compose -f docker-compose.yml down --remove-orphans "$@"
    ;;
  clean)
    export COMPOSE_PROJECT_NAME
    shift
    exec docker compose -f "$CLI_FILE" run --rm -e COMPOSE_PROJECT_NAME clean "$@"
    ;;
  import-themes)
    shift
    export COMPOSE_PROJECT_NAME
    export SKIP_CLONE="${SKIP_CLONE:-0}"
    export CLONE_ONLY="${CLONE_ONLY:-0}"
    for _a in "$@"; do
      case "$_a" in
        --skip-clone) export SKIP_CLONE=1 ;;
        --clone-only) export CLONE_ONLY=1 ;;
      esac
    done
    exec docker compose -f "$CLI_FILE" run --rm \
      -e COMPOSE_PROJECT_NAME -e SKIP_CLONE -e CLONE_ONLY \
      -e THEME_WIKI_REPO -e THEME_DIR_NAME -e BAKLIB_CLI_IMAGE \
      import-themes
    ;;
  -h|--help|"")
    usage
    exit 0
    ;;
  *)
    echo "未知子命令: ${1:-}"
    usage
    exit 1
    ;;
esac
