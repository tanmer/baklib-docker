#!/bin/bash

# 公共函数库
# 用于所有脚本的通用函数

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "未找到 $1 命令，请先安装 Docker"
        exit 1
    fi
}

# 检查 Docker 是否运行
check_docker_running() {
    if ! docker info &> /dev/null; then
        print_error "Docker 未运行，请先启动 Docker"
        exit 1
    fi
}

# 读取 .env 文件中的值
read_env_value() {
    local key=$1
    if [ -f ".env" ]; then
        # 读取配置值，去掉引号，去掉注释（# 及其后面的内容），去掉首尾空格
        local raw_value=$(grep "^${key}=" .env 2>/dev/null | cut -d'=' -f2- | sed 's/#.*$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -1)
        if [ -n "$raw_value" ]; then
            # 去掉首尾的引号（支持单引号和双引号）
            # 先去掉首尾的双引号
            raw_value=$(echo "$raw_value" | sed 's/^"//;s/"$//')
            # 再去掉首尾的单引号
            raw_value=$(echo "$raw_value" | sed "s/^'//;s/'$//")
            # 去掉末尾多余的引号（处理类似 "value"" 或 value"" 的情况）
            # 使用 sed 去掉末尾连续的双引号或单引号
            while true; do
                local new_value=$(echo "$raw_value" | sed 's/""$//;s/'\''\'\''$//')
                if [ "$new_value" = "$raw_value" ]; then
                    break
                fi
                raw_value="$new_value"
            done
            # 如果值末尾还有单个引号，且值本身不是以引号开头，则去掉
            if echo "$raw_value" | grep -qE '[^"'\'']$' || echo "$raw_value" | grep -qE '^["'\'']'; then
                # 值不以引号结尾，或者以引号开头，不需要处理
                :
            else
                # 值以引号结尾但开头不是引号，去掉末尾的引号
                raw_value=$(echo "$raw_value" | sed 's/["'\'']$//')
            fi
            echo "$raw_value"
        fi
    fi
}

# 交互式输入配置项
prompt_config() {
    local key=$1
    local description=$2
    local default_value=$(read_env_value "$key")
    local value=""
    local prompt_text=""

    # 构建提示文本
    if [ -n "$default_value" ]; then
        prompt_text="$description [$default_value]: "
    else
        prompt_text="$description: "
    fi

    # 使用 read -p 直接提示并读取
    # read -p 会将提示输出到 stderr，所以不会被变量捕获
    if [ -t 0 ]; then
        # 如果 stdin 是终端，直接读取
        read -p "$prompt_text" value
    else
        # 如果 stdin 不是终端（比如在管道中），尝试从 /dev/tty 读取
        read -p "$prompt_text" value < /dev/tty
    fi

    if [ -z "$value" ] && [ -n "$default_value" ]; then
        value="$default_value"
    fi

    # 将结果输出到 stdout
    echo "$value"
}

# 更新 .env 文件
update_env_file() {
    local key=$1
    local value=$2

    if grep -q "^${key}=" .env 2>/dev/null; then
        # 更新现有配置
        if [ -z "$value" ]; then
            # 如果值为空，删除该行
            if sed --version >/dev/null 2>&1; then
                sed -i "/^${key}=/d" .env
            else
                sed -i '' "/^${key}=/d" .env
            fi
        else
            # 如果值包含空格或特殊字符，需要加引号
            if echo "$value" | grep -qE '[ "$`]'; then
                if sed --version >/dev/null 2>&1; then
                    sed -i "s|^${key}=.*|${key}=\"${value}\"|" .env
                else
                    sed -i '' "s|^${key}=.*|${key}=\"${value}\"|" .env
                fi
            else
                if sed --version >/dev/null 2>&1; then
                    sed -i "s|^${key}=.*|${key}=${value}|" .env
                else
                    sed -i '' "s|^${key}=.*|${key}=${value}|" .env
                fi
            fi
        fi
    else
        # 添加新配置（如果值不为空）
        if [ -n "$value" ]; then
            if echo "$value" | grep -qE '[ "$`]'; then
                echo "${key}=\"${value}\"" >> .env
            else
                echo "${key}=${value}" >> .env
            fi
        fi
    fi
}

# 获取 Docker Compose 命令
get_compose_cmd() {
    if docker compose version &> /dev/null; then
        echo "docker compose"
    else
        echo "docker-compose"
    fi
}

# 验证 .env 文件语法
# 返回 0 表示语法正确，返回 1 表示有错误
validate_env_file() {
    local env_file="${1:-.env}"
    
    if [ ! -f "$env_file" ]; then
        print_error ".env 文件不存在: $env_file"
        return 1
    fi
    
    # 首先进行基本的引号和语法检查
    local line_num=0
    local errors=0
    
    while IFS= read -r line || [ -n "$line" ]; do
        line_num=$((line_num + 1))
        
        # 跳过空行和注释行
        if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 检查是否有未匹配的引号（检查双引号）
        local double_quotes=$(echo "$line" | grep -o '"' | wc -l | tr -d ' ')
        if [ $((double_quotes % 2)) -ne 0 ]; then
            print_error ".env 文件第 $line_num 行有未匹配的双引号:"
            echo "  $line"
            errors=$((errors + 1))
            continue
        fi
        
        # 检查是否有连续的双引号（可能是多余的引号，如 value""）
        if echo "$line" | grep -qE '"[^"]*""|""[^"]*"'; then
            print_error ".env 文件第 $line_num 行可能有多余的引号:"
            echo "  $line"
            errors=$((errors + 1))
            continue
        fi
        
        # 检查变量名中是否包含引号（这是非法的）
        local var_part=$(echo "$line" | cut -d'=' -f1 | sed 's/[[:space:]]*$//')
        # 使用更可靠的方式检查引号：直接检查字符
        if echo "$var_part" | grep -qE '["'\''"]'; then
            print_error ".env 文件第 $line_num 行变量名包含非法字符（引号）:"
            echo "  $line"
            errors=$((errors + 1))
            continue
        fi
        
        # 检查变量名格式（必须以字母或下划线开头）
        if [[ ! "$line" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*= ]] && [[ ! "$line" =~ ^[[:space:]]*# ]]; then
            # 检查是否是明显的错误（变量名以非字母开头且不是注释）
            if [[ "$line" =~ ^[[:space:]]*[^A-Za-z_#\"\047] ]]; then
                print_error ".env 文件第 $line_num 行变量名格式错误:"
                echo "  $line"
                errors=$((errors + 1))
            fi
        fi
    done < "$env_file"
    
    if [ $errors -gt 0 ]; then
        print_error ".env 文件发现 $errors 个语法错误，请修复后再继续"
        return 1
    fi
    
    # 使用 Docker Compose 来进一步验证（如果可用）
    local COMPOSE_CMD=$(get_compose_cmd)
    if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
        local compose_file="docker-compose.yml"
        if [ -f "$compose_file" ]; then
            # 尝试使用 docker compose config 来验证配置
            # 这会读取 .env 文件，如果有语法错误会报错
            local error_output=$($COMPOSE_CMD --env-file "$env_file" config 2>&1)
            local exit_code=$?
            
            if [ $exit_code -ne 0 ]; then
                # 检查是否是 .env 文件相关的错误
                if echo "$error_output" | grep -qE "(\.env|unexpected|syntax|variable name|failed to read)"; then
                    print_error "Docker Compose 解析 .env 文件时出错："
                    echo "$error_output" | grep -E "(\.env|unexpected|syntax|variable name|failed to read|line [0-9]+)" | head -5
                    return 1
                fi
                # 如果是其他错误（如 docker-compose.yml 的问题），不返回错误
            fi
        fi
    fi
    
    return 0
}

# 初始化 etcd 认证
# 参数:
#   $1: Docker Compose 命令（通过 get_compose_cmd 获取）
#   $2: etcd root 密码
#   $3: 是否重启服务（可选，默认为 false）
init_etcd_auth() {
    local COMPOSE_CMD="$1"
    local ETCD_ROOT_PASSWORD="$2"
    local RESTART_SERVICES="${3:-false}"
    
    if [ -z "$COMPOSE_CMD" ] || [ -z "$ETCD_ROOT_PASSWORD" ]; then
        print_error "init_etcd_auth: 缺少必需参数"
        return 1
    fi
    
    # 等待 etcd 集群就绪
    print_info "等待 etcd 集群就绪..."
    local etcd_ready=false
    for i in {1..30}; do
        if $COMPOSE_CMD exec -T etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 endpoint health >/dev/null 2>&1; then
            print_success "etcd 集群已就绪"
            etcd_ready=true
            break
        fi
        if [ $i -eq 30 ]; then
            print_error "etcd 集群未能在 30 秒内就绪"
            return 1
        fi
        sleep 1
    done
    
    if [ "$etcd_ready" != "true" ]; then
        return 1
    fi
    
    # 检查认证是否已启用
    print_info "检查 etcd 认证状态..."
    local AUTH_STATUS_OUTPUT=$($COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 auth status 2>/dev/null || echo "")
    # 检查输出中是否包含 "Authentication Status: true" 或 "enabled"
    local AUTH_ENABLED=$(echo "$AUTH_STATUS_OUTPUT" | grep -iE "(Authentication Status: true|enabled)" || echo "")
    
    if [ -n "$AUTH_ENABLED" ]; then
        print_success "etcd 认证已启用，无需重复初始化"
        return 0
    fi
    
    # 创建 root 用户（如果不存在）
    print_info "创建 root 用户..."
    if ! $COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 user list 2>/dev/null | grep -q "^root$"; then
        if echo "$ETCD_ROOT_PASSWORD" | $COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 user add root --interactive=false 2>/dev/null; then
            print_success "root 用户已创建"
        else
            print_warning "root 用户可能已存在或创建失败"
        fi
    else
        print_info "root 用户已存在"
    fi
    
    # 为 root 用户分配 root 角色
    print_info "为 root 用户分配 root 角色..."
    $COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 user grant-role root root 2>/dev/null || true
    
    # 启用认证
    print_info "启用 etcd 认证..."
    if $COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 auth enable 2>/dev/null; then
        print_success "etcd 认证已启用"
        
        # 验证认证
        print_info "验证 etcd 认证..."
        sleep 2
        if $COMPOSE_CMD exec -T -e ETCDCTL_API=3 etcd01 /usr/local/bin/etcdctl --endpoints=http://localhost:2379 --user=root:"$ETCD_ROOT_PASSWORD" endpoint health >/dev/null 2>&1; then
            print_success "etcd 认证验证成功"
        else
            print_warning "etcd 认证验证失败，但认证可能已启用"
        fi
        
        # 如果需要，重启服务
        if [ "$RESTART_SERVICES" = "true" ]; then
            print_info "重启 Traefik 以应用 etcd 认证..."
            $COMPOSE_CMD restart traefik
            
            print_info "重启应用服务以应用 etcd 认证..."
            $COMPOSE_CMD restart baklib-web baklib-job baklib-saas baklib-api baklib-trial 2>/dev/null || true
            
            print_success "相关服务已重启"
        fi
        
        return 0
    else
        print_error "etcd 认证启用失败"
        return 1
    fi
}

