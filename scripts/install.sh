#!/bin/bash

# install：仅负责准备（登录镜像仓库、拉取镜像），不执行 config。
# 步骤顺序：先 config（生成/更新 .env）→ 再 install（准备）→ 再 start（启动）。

# 加载公共函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

echo "=========================================="
echo "🚀 Baklib 安装（准备镜像）"
echo "=========================================="
echo ""

# 1. 检查环境
print_info "检查环境..."
check_command docker
if ! docker compose version &> /dev/null && ! docker-compose version &> /dev/null; then
    print_error "未找到 docker compose 命令，请先安装 Docker Compose"
    exit 1
fi
check_docker_running
print_success "环境检查通过"
echo ""

# 2. 必须有 .env（由 config 生成）
if [ ! -f ".env" ]; then
    print_error "未找到 .env 文件，请先执行 config 生成/更新配置后再执行 install。"
    echo "  示例: ./baklib config"
    exit 1
fi

COMPOSE_CMD=$(get_compose_cmd)
# 仅检查主栈的 web 服务是否在运行，避免把 CLI 容器（如本 install 容器）误判为主栈
if $COMPOSE_CMD ps web --status running 2>/dev/null | grep -q web; then
    print_error "检测到主栈（web）已在运行，无法执行 install。"
    echo ""
    echo "请先卸载或停止主栈后再执行 install："
    echo "  ./baklib uninstall   - 停止并移除容器（保留 .env 与数据卷）"
    echo "  或: docker compose -f docker-compose.yml down --remove-orphans"
    echo ""
    echo "若仅需更新镜像版本，可修改 .env 中的 IMAGE_TAG 后执行："
    echo "  docker compose pull"
    echo "  再执行 restart"
    echo ""
    exit 1
fi

# 3. Docker 镜像仓库登录（在拉取镜像之前）
print_info "检查 Docker 镜像仓库认证..."

# Docker 镜像仓库地址（固定）
REGISTRY_SERVER_CHECK="registry.devops.tanmer.com"

REGISTRY_USERNAME_CHECK=$(read_env_value "REGISTRY_USERNAME")
REGISTRY_PASSWORD_CHECK=$(read_env_value "REGISTRY_PASSWORD")

if [ -n "$REGISTRY_USERNAME_CHECK" ] && [ -n "$REGISTRY_PASSWORD_CHECK" ]; then
    print_info "正在登录 Docker 镜像仓库: $REGISTRY_SERVER_CHECK"
    # 使用 printf 避免密码中含换行等字符时影响 --password-stdin
    if printf '%s' "$REGISTRY_PASSWORD_CHECK" | docker login "$REGISTRY_SERVER_CHECK" --username "$REGISTRY_USERNAME_CHECK" --password-stdin; then
        print_success "Docker 镜像仓库登录成功"
    else
        print_error "Docker 镜像仓库登录失败，无法拉取私有镜像。"
        echo "请检查 .env 中的 REGISTRY_USERNAME、REGISTRY_PASSWORD 是否正确，或重新运行 config 填写凭证。"
        echo "确认无误后可再次执行 install。"
        exit 1
    fi
else
    print_warning "未配置 Docker 镜像仓库认证信息（REGISTRY_USERNAME 和 REGISTRY_PASSWORD）"
    print_warning "私有镜像将无法拉取。请运行 config 填写凭证后再执行 install。"
    read -p "是否仍继续尝试拉取？(y/N): " confirm 2>/dev/null || true
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消。请先运行 config 配置 REGISTRY_USERNAME 和 REGISTRY_PASSWORD 后再执行 install。"
        exit 1
    fi
fi
echo ""

# 4. 拉取镜像
print_info "拉取 Docker 镜像..."
if ! $COMPOSE_CMD pull; then
    print_error "镜像拉取失败！请检查："
    echo "  1. 网络连接是否正常"
    echo "  2. Docker 镜像仓库认证是否正确（检查 .env 文件中的 REGISTRY_USERNAME 和 REGISTRY_PASSWORD）"
    echo "  3. .env 文件中的镜像配置是否正确"
    echo ""
    echo "如需重新配置认证信息，请运行: ./baklib config"
    exit 1
fi
print_success "镜像拉取完成"
echo ""

# 5. 若已配置 ADMIN_PHONE：run --rm web 执行 db:prepare 与更新管理员，然后 down 清理
ADMIN_PHONE=$(read_env_value "ADMIN_PHONE")
if [ -n "$ADMIN_PHONE" ]; then
    # 宿主机上 product.pem 不存在时，Docker 会把挂载点变成目录，导致应用 EISDIR；先确保是文件
    if [ ! -f "product.pem" ]; then
        touch product.pem
        print_warning "product.pem 不存在，已创建空文件；请向客服申请证书后替换该文件。"
    fi
    print_info "已配置管理员手机号，临时启动 web 执行数据库初始化并写入首个用户登录账号..."
    print_info "执行 bin/rails db:prepare（会按需启动依赖容器）..."
    if ! $COMPOSE_CMD run --rm web bin/rails db:prepare; then
        print_error "db:prepare 失败"
        $COMPOSE_CMD down 2>/dev/null || true
        exit 1
    fi
    print_info "写入首个用户登录手机号..."
    RUNNER_CODE='u=User.order(:id).first; exit(0) if !u || ENV["ADMIN_PHONE"].to_s.empty?; u.update!(mobile_phone: ENV["ADMIN_PHONE"]) if u.respond_to?(:mobile_phone=); puts "OK"'
    if $COMPOSE_CMD run --rm -e "ADMIN_PHONE=$ADMIN_PHONE" web bin/rails runner "$RUNNER_CODE" 2>/dev/null | grep -q "OK"; then
        print_success "首个用户登录手机号已设置为: $ADMIN_PHONE"
    else
        print_warning "未能自动写入首个用户手机号（可能尚无用户记录），安装后可手动执行："
        echo "  docker compose run --rm -e ADMIN_PHONE=你的手机号 web bin/rails runner 'User.order(:id).first&.update!(mobile_phone: ENV[\"ADMIN_PHONE\"])'"
    fi
    print_info "停止并移除安装过程中启动的容器..."
    $COMPOSE_CMD down 2>/dev/null || true
    echo ""
fi

print_success "安装完成！"
echo ""
echo "接下来可运行 start 启动服务，首次部署后运行 import-themes 导入主题。"
echo "  ./baklib start         - 启动服务"
echo "  ./baklib import-themes - 导入主题模版（首次必选，需服务已启动）"
echo ""
