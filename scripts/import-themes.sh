#!/bin/bash

# 导入主题（模版）到数据库（首次安装必选，需在服务已正常启动后执行）
# 从 Gitee 公开仓库 https://gitee.com/baklib/theme-wiki 克隆 Wiki 模板，并执行 bin/rails themes:import 写入数据库

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/common.sh"

THEME_WIKI_REPO="${THEME_WIKI_REPO:-https://gitee.com/baklib/theme-wiki.git}"
THEME_DIR_NAME="${THEME_DIR_NAME:-theme-wiki}"
THEME_IMPORT_DIR="/rails/theme_repositories/${THEME_DIR_NAME}"

usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "首次安装必选，需在服务已正常启动后执行。从 Gitee 克隆 theme-wiki 模板到主题仓库卷，并执行 themes:import 导入到数据库。"
    echo ""
    echo "选项:"
    echo "  --skip-clone    跳过克隆，仅执行导入（适用于主题目录已存在）"
    echo "  --clone-only    仅克隆仓库，不执行导入"
    echo "  -h, --help      显示此帮助"
    echo ""
    echo "环境变量:"
    echo "  THEME_WIKI_REPO   主题仓库 URL（默认: https://gitee.com/baklib/theme-wiki.git）"
    echo "  THEME_DIR_NAME    克隆后的目录名（默认: theme-wiki）"
}

SKIP_CLONE=false
CLONE_ONLY=false
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-clone)  SKIP_CLONE=true ;;
        --clone-only)  CLONE_ONLY=true ;;
        -h|--help)     usage; exit 0 ;;
        *)             echo "未知选项: $1"; usage; exit 1 ;;
    esac
    shift
done

COMPOSE_CMD=$(get_compose_cmd)
check_command docker
check_docker_running

if [ ! -f ".env" ]; then
    print_error "未找到 .env 文件，请先运行 ./baklib config 或完成安装"
    exit 1
fi

# 1. 克隆主题仓库到 volume（可选）
# 使用临时 Alpine 容器挂载主题卷并克隆（shell 服务挂载为只读，无法写入）
if [ "$SKIP_CLONE" = false ]; then
    THEME_VOLUME=$(docker volume ls --format '{{.Name}}' | grep 'baklib-theme-repositories' | head -1)
    if [ -z "$THEME_VOLUME" ]; then
        print_info "主题卷尚未创建，先启动一次 web 以创建卷..."
        $COMPOSE_CMD run --rm --no-deps web true 2>/dev/null || true
        THEME_VOLUME=$(docker volume ls --format '{{.Name}}' | grep 'baklib-theme-repositories' | head -1)
    fi
    if [ -z "$THEME_VOLUME" ]; then
        print_error "无法获取主题卷名称，请先执行 ./baklib start 启动服务后再运行本脚本"
        exit 1
    fi
    print_info "将 theme-wiki 克隆到主题仓库卷..."
    if ! docker run --rm -v "${THEME_VOLUME}:/data" -w /data alpine sh -c "apk add --no-cache git >/dev/null 2>&1 && (test -d ${THEME_DIR_NAME} && (cd ${THEME_DIR_NAME} && git pull --ff-only) || git clone --depth 1 ${THEME_WIKI_REPO} ${THEME_DIR_NAME})"; then
        print_error "克隆主题仓库失败，请检查网络或仓库地址: ${THEME_WIKI_REPO}"
        exit 1
    fi
    print_success "主题仓库已就绪: ${THEME_DIR_NAME}"
fi

[ "$CLONE_ONLY" = true ] && exit 0

# 2. 确保 web 服务在运行（使用与宿主机一致的 COMPOSE_PROJECT_NAME，由 baklib/baklib.cmd 传入）
if ! $COMPOSE_CMD ps web --status running 2>/dev/null | grep -q web; then
    print_error "Web 服务未运行，请先执行 ./baklib start 启动服务"
    if [ -n "${COMPOSE_PROJECT_NAME:-}" ]; then
        echo "  当前项目名: COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}"
        echo "  请确保在与执行 start 时相同的目录下运行 import-themes。"
    fi
    exit 1
fi

# 3. 执行 themes:import
print_info "正在将主题导入数据库: dir=${THEME_IMPORT_DIR}"
if ! $COMPOSE_CMD exec -T web bin/rails themes:import "dir=${THEME_IMPORT_DIR}"; then
    print_error "主题导入失败"
    exit 1
fi

# 4. 将导入的主题设为已发布（默认未发布）
print_info "正在将主题设为已发布..."
if ! $COMPOSE_CMD exec -T web bin/rails runner 'Theme.first.update(published_at: Time.zone.now)'; then
    print_warning "主题发布状态更新失败（可能需在应用内手动发布）"
else
    print_success "主题已设为已发布"
fi

print_success "主题已导入到数据库，可在应用中使用 Wiki 模板。"
