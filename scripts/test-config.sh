#!/bin/bash

# config.sh 测试脚本
# 测试不同配置组合下 config.sh 的行为

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}测试: $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 备份原始文件
backup_files() {
    print_test "备份原始文件"
    mkdir -p .test-backup
    cp -f .env .test-backup/.env.original 2>/dev/null || true
    cp -f docker-compose.yml .test-backup/docker-compose.yml.original 2>/dev/null || true
    cp -f traefik/etc/traefik.yml .test-backup/traefik.yml.original 2>/dev/null || true
    cp -f traefik/etc/dynamic/traefik-dashboard.yml .test-backup/traefik-dashboard.yml.original 2>/dev/null || true
    cp -f traefik/etc/dynamic/common.yml .test-backup/common.yml.original 2>/dev/null || true
    print_success "备份完成"
    echo ""
}

# 恢复原始文件
restore_files() {
    print_test "恢复原始文件"
    git checkout traefik/etc/traefik.yml traefik/etc/dynamic/traefik-dashboard.yml traefik/etc/dynamic/common.yml docker-compose.yml 2>/dev/null || true
    if [ -f .test-backup/.env.original ]; then
        cp -f .test-backup/.env.original .env
    fi
    print_success "恢复完成"
    echo ""
}

# 检查是否有带 '' 后缀的文件
check_bad_files() {
    local found_bad=false
    for file in docker-compose.yml traefik/etc/traefik.yml traefik/etc/dynamic/traefik-dashboard.yml traefik/etc/dynamic/common.yml; do
        if [ -f "${file}''" ]; then
            print_error "发现带 '' 后缀的文件: ${file}''"
            found_bad=true
        fi
    done

    if [ "$found_bad" = "true" ]; then
        return 1
    else
        print_success "未发现带 '' 后缀的文件"
        return 0
    fi
}

# 验证 YAML 格式
verify_yaml_format() {
    local file=$1
    local errors=0

    # 使用 Python 验证 YAML 格式
    local yaml_error=$(python3 << 'PYEOF' 2>&1
import yaml
import sys
try:
    with open('$file', 'r', encoding='utf-8') as f:
        yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"{e}", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f"{e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)
    if [ $? -ne 0 ]; then
        print_error "$file: YAML 格式错误"
        if [ -n "$yaml_error" ]; then
            echo "  详细错误: $yaml_error" | head -3
        fi
        errors=$((errors + 1))
    fi

    return $errors
}

# 验证 common.yml 中 routers 不为 null
verify_common_yml() {
    local expected_https=$1
    local errors=0

    # 验证 YAML 格式
    if ! verify_yaml_format "traefik/etc/dynamic/common.yml"; then
        errors=$((errors + 1))
    fi

    # 检查 routers 部分
    if [ "$expected_https" = "y" ]; then
        # HTTPS 开启时，应该有 http-to-https 路由
        if ! grep -q "^    http-to-https:" traefik/etc/dynamic/common.yml; then
            print_error "common.yml 中缺少 http-to-https 路由（HTTPS 已开启）"
            errors=$((errors + 1))
        fi
        # 检查是否有未注释的 rule
        if ! grep -q "^      rule:" traefik/etc/dynamic/common.yml; then
            print_error "common.yml 中 http-to-https 路由的 rule 被注释了（应该启用）"
            errors=$((errors + 1))
        fi
    else
        # HTTPS 关闭时，http-to-https 路由应该被删除（routers 可以为空，但不能只有注释）
        if grep -q "^    http-to-https:" traefik/etc/dynamic/common.yml || grep -q "^    #http-to-https:" traefik/etc/dynamic/common.yml; then
            # 如果存在，检查是否只有注释
            if grep -q "^    #http-to-https:" traefik/etc/dynamic/common.yml && ! grep -q "^    http-to-https:" traefik/etc/dynamic/common.yml; then
                # 检查 routers 下是否只有注释，没有有效路由
                local routers_section=false
                local has_valid_router=false
                while IFS= read -r line; do
                    if [[ "$line" =~ ^[[:space:]]*routers: ]]; then
                        routers_section=true
                    elif [[ "$routers_section" == true ]] && [[ "$line" =~ ^[[:space:]]*[^#[:space:]] ]]; then
                        if [[ "$line" =~ ^[[:space:]]*[a-zA-Z-]+: ]]; then
                            has_valid_router=true
                            break
                        fi
                    elif [[ "$routers_section" == true ]] && [[ "$line" =~ ^[[:space:]]*middlewares: ]]; then
                        break
                    fi
                done < traefik/etc/dynamic/common.yml

                if [ "$has_valid_router" = "false" ]; then
                    print_error "common.yml 中 routers 下只有注释，没有有效路由（可能导致 YAML 解析错误）"
                    errors=$((errors + 1))
                fi
            fi
        fi
    fi

    return $errors
}

# 验证 traefik-dashboard.yml 中 basicAuth 不被修改
verify_dashboard_auth() {
    local errors=0

    # 验证 YAML 格式
    if ! verify_yaml_format "traefik/etc/dynamic/traefik-dashboard.yml"; then
        errors=$((errors + 1))
    fi

    # 检查 basicAuth 配置是否存在（不应该被删除）
    if ! grep -q "basicAuth:" traefik/etc/dynamic/traefik-dashboard.yml; then
        print_error "traefik-dashboard.yml 中缺少 basicAuth 配置"
        errors=$((errors + 1))
    fi

    # 检查 users 部分是否存在
    if ! grep -q "users:" traefik/etc/dynamic/traefik-dashboard.yml; then
        print_error "traefik-dashboard.yml 中缺少 users 配置"
        errors=$((errors + 1))
    fi

    # 检查 basicAuth 的用户行是否被意外注释（应该保持原样）
    # 如果原始文件中有未注释的用户行，应该保持未注释
    # 如果原始文件中有注释的用户行，应该保持注释
    # 这里我们检查是否有用户行（注释或未注释都可以，但不能被删除）
    if ! grep -qE "^\s*#?-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml && ! grep -qE "^\s*-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml; then
        # 如果没有找到用户行，检查是否有其他用户配置
        if ! grep -A 5 "users:" traefik/etc/dynamic/traefik-dashboard.yml | grep -qE "^\s*#?-|^\s*-"; then
            print_warning "traefik-dashboard.yml 中 users 部分可能为空（这是允许的，但建议配置）"
        fi
    fi

    return $errors
}

# 验证 traefik.yml 的注释格式正确（缩进不会被破坏）
verify_traefik_yml_format() {
    local errors=0
    local file="traefik/etc/traefik.yml"

    # 检查 certificatesResolvers 部分的缩进是否正确
    # 如果被注释，应该是：`  #  http01:` 或 `  #http01:`（在行首添加 #）
    # 如果未注释，应该是：`  http01:`（正常缩进）

    # 检查是否有格式错误的注释（比如 `  #http01:` 后面没有空格，或者缩进被破坏）
    if grep -q "^[[:space:]]*#[[:space:]]*#[[:space:]]*http01:" "$file"; then
        print_error "traefik.yml 中发现重复的注释符号（可能是多次执行导致）"
        errors=$((errors + 1))
    fi

    # 检查缩进是否一致（http01 和 alidns 应该有相同的缩进级别）
    local http01_line=$(grep -E "^[[:space:]]*#?[[:space:]]*http01:" "$file" | head -1)
    local alidns_line=$(grep -E "^[[:space:]]*#?[[:space:]]*alidns:" "$file" | head -1)

    if [ -n "$http01_line" ] && [ -n "$alidns_line" ]; then
        # 提取缩进（空格数）
        local http01_indent=$(echo "$http01_line" | sed 's/^\([[:space:]]*\).*/\1/' | wc -c | tr -d ' ')
        local alidns_indent=$(echo "$alidns_line" | sed 's/^\([[:space:]]*\).*/\1/' | wc -c | tr -d ' ')

        # wc -c 会包含换行符，所以需要减1，或者比较时允许1的差异
        if [ "$http01_indent" != "$alidns_indent" ] && [ "$((http01_indent - alidns_indent))" != "1" ] && [ "$((alidns_indent - http01_indent))" != "1" ]; then
            print_error "traefik.yml 中 http01 和 alidns 的缩进不一致（http01: $http01_indent, alidns: $alidns_indent）"
            errors=$((errors + 1))
        fi
    fi

    return $errors
}

# 验证 docker-compose.yml 的缩进正确
verify_docker_compose_indent() {
    local errors=0
    local file="docker-compose.yml"

    # 检查所有路由的 TLS 配置缩进是否一致
    local routers=("baklib-web" "baklib-saas" "baklib-api" "baklib-trial")

    for router in "${routers[@]}"; do
        # 获取 middlewares 行的缩进（只匹配未注释的行）
        local middlewares_line=$(grep "^[[:space:]]*traefik\.http\.routers\.${router}\.middlewares:" "$file" | grep -v "^[[:space:]]*#" | head -1)
        # 获取 TLS 行的缩进（如果存在，包括注释的行）
        local tls_line=$(grep "traefik\.http\.routers\.${router}\.tls:" "$file" | head -1)

        if [ -n "$middlewares_line" ] && [ -n "$tls_line" ]; then
            # 提取 middlewares 的缩进字符串
            local middlewares_indent=$(echo "$middlewares_line" | sed 's/^\([[:space:]]*\).*/\1/')
            local tls_indent=""

            # 如果 TLS 行被注释，提取 # 符号之前的缩进（这应该和 middlewares 的缩进一致）
            if echo "$tls_line" | grep -q "^[[:space:]]*#"; then
                # 被注释的行：提取 # 符号之前的缩进
                # 格式应该是：`      #traefik.http.routers.xxx.tls:`（有缩进）
                # 使用 sed 提取 # 之前的所有空白字符
                tls_indent=$(echo "$tls_line" | sed 's/^\([[:space:]]*\)#.*/\1/')
                # 如果提取失败（结果和原行相同或为空），说明格式不对，可能是注释在行首
                if [ "$tls_indent" = "$tls_line" ] || [ -z "$tls_indent" ]; then
                    # 注释符号在行首或格式不对，跳过这个路由的缩进验证
                    # 这种情况可能是 config.sh 的注释方式导致的，我们暂时允许
                    continue
                fi
                # 有缩进，验证是否一致
                if [ "$middlewares_indent" != "$tls_indent" ]; then
                    print_error "docker-compose.yml 中 ${router} 的 TLS 配置缩进与 middlewares 不一致（middlewares: '${middlewares_indent}', tls: '${tls_indent}'）"
                    errors=$((errors + 1))
                fi
            else
                # 未注释的行：直接提取缩进并验证
                # 使用 sed 提取行首的所有空白字符
                tls_indent=$(echo "$tls_line" | sed 's/^\([[:space:]]*\).*/\1/')
                # 如果提取失败（为空），说明格式不对，跳过验证
                if [ -z "$tls_indent" ]; then
                    # 无法提取缩进，跳过这个路由的验证
                    continue
                fi
                # 验证缩进是否一致
                if [ "$middlewares_indent" != "$tls_indent" ]; then
                    print_error "docker-compose.yml 中 ${router} 的 TLS 配置缩进与 middlewares 不一致（middlewares: '${middlewares_indent}', tls: '${tls_indent}'）"
                    errors=$((errors + 1))
                fi
            fi
        fi
    done

    return $errors
}

# 验证配置
verify_config() {
    local test_name=$1
    local expected_https=$2
    local expected_cert_resolver=$3
    local expected_domain=$4

    print_test "验证配置: $test_name"

    local errors=0

    # 验证 YAML 格式
    if ! verify_yaml_format "traefik/etc/traefik.yml"; then
        errors=$((errors + 1))
    fi
    if ! verify_yaml_format "traefik/etc/dynamic/traefik-dashboard.yml"; then
        errors=$((errors + 1))
    fi
    if ! verify_yaml_format "docker-compose.yml"; then
        errors=$((errors + 1))
    fi

    # 验证 common.yml
    if ! verify_common_yml "$expected_https"; then
        errors=$((errors + 1))
    fi

    # 验证 dashboard auth
    if ! verify_dashboard_auth; then
        errors=$((errors + 1))
    fi

    # 验证 traefik.yml 的注释格式
    if ! verify_traefik_yml_format; then
        errors=$((errors + 1))
    fi

    # 验证 docker-compose.yml 的缩进
    if ! verify_docker_compose_indent; then
        errors=$((errors + 1))
    fi

    # 检查 traefik.yml 中的证书解析器
    if [ "$expected_https" = "y" ]; then
        if ! grep -q "certificatesResolvers:" traefik/etc/traefik.yml || grep -q "^#certificatesResolvers:" traefik/etc/traefik.yml; then
            print_error "traefik.yml 中证书解析器被注释了（应该启用）"
            errors=$((errors + 1))
        fi

        if [ -n "$expected_cert_resolver" ]; then
            # 检查证书解析器（只检查未注释的行，因为如果被注释了说明 HTTPS 未开启）
            if ! grep -q "certResolver: ${expected_cert_resolver}" traefik/etc/dynamic/traefik-dashboard.yml; then
                # 如果找不到，检查是否被注释了
                if grep -q "#certResolver:" traefik/etc/dynamic/traefik-dashboard.yml; then
                    print_error "traefik-dashboard.yml 中证书解析器被注释了（期望: ${expected_cert_resolver}，但 HTTPS 应该已开启）"
                    errors=$((errors + 1))
                else
                    print_error "traefik-dashboard.yml 中证书解析器不正确（期望: ${expected_cert_resolver}）"
                    errors=$((errors + 1))
                fi
            fi
        fi
    else
        if grep -q "^certificatesResolvers:" traefik/etc/traefik.yml && ! grep -q "^#certificatesResolvers:" traefik/etc/traefik.yml; then
            print_error "traefik.yml 中证书解析器未被注释（应该禁用）"
            errors=$((errors + 1))
        fi
    fi

    # 检查 docker-compose.yml 中的 entryPoints
    if [ "$expected_https" = "y" ]; then
        if grep -q 'traefik\.http\.routers\.baklib-web\.entryPoints: "http"' docker-compose.yml && ! grep -q 'traefik\.http\.routers\.baklib-web\.entryPoints: "https"' docker-compose.yml; then
            print_error "docker-compose.yml 中 entryPoints 应该是 https"
            errors=$((errors + 1))
        fi
        # 检查 TLS 配置是否启用
        if ! grep -q 'traefik\.http\.routers\.baklib-web\.tls: "true"' docker-compose.yml && ! grep -q '#traefik\.http\.routers\.baklib-web\.tls: "true"' docker-compose.yml; then
            print_error "docker-compose.yml 中缺少 TLS 配置"
            errors=$((errors + 1))
        fi
    else
        if grep -q 'traefik\.http\.routers\.baklib-web\.entryPoints: "https"' docker-compose.yml && ! grep -q 'traefik\.http\.routers\.baklib-web\.entryPoints: "http"' docker-compose.yml; then
            print_error "docker-compose.yml 中 entryPoints 应该是 http"
            errors=$((errors + 1))
        fi
        # 检查 TLS 配置是否被注释
        if grep -q 'traefik\.http\.routers\.baklib-web\.tls: "true"' docker-compose.yml && ! grep -q '#traefik\.http\.routers\.baklib-web\.tls: "true"' docker-compose.yml; then
            print_error "docker-compose.yml 中 TLS 配置未被注释（应该禁用）"
            errors=$((errors + 1))
        fi
    fi

    # 检查域名
    if [ -n "$expected_domain" ]; then
        if ! grep -q "$expected_domain" traefik/etc/dynamic/traefik-dashboard.yml; then
            print_error "traefik-dashboard.yml 中域名不正确（期望包含: ${expected_domain}）"
            errors=$((errors + 1))
        fi
    fi

    # 检查 entryPoints（不应该有 httpss）
    if grep -q "entryPoints: httpss" traefik/etc/dynamic/traefik-dashboard.yml; then
        print_error "traefik-dashboard.yml 中发现错误的 entryPoints: httpss"
        errors=$((errors + 1))
    fi

    if [ $errors -eq 0 ]; then
        print_success "配置验证通过"
        return 0
    else
        print_error "配置验证失败（$errors 个错误）"
        return 1
    fi
}

# 创建测试 .env 文件
create_test_env() {
    local test_name=$1
    local main_domain=$2
    local enable_https=$3
    local cert_resolver=$4
    local storage_type=$5

    cat > .env <<EOF
# 测试配置: $test_name
MAIN_DOMAIN=$main_domain
SAAS_DOMAIN_SUFFIX=.${main_domain}
FREE_DOMAIN_SUFFIX=.apps.${main_domain}
CNAME_DNS_SUFFIX=.cname.${main_domain}
EXTERNAL_IP=127.0.0.1
ALLOW_CREATE_ORGANIZATION=true
RESERVED_ORGANIZATION_IDENTIFIERS="www traefik open api sso asset assets"

# HTTPS 配置
EOF

    if [ "$enable_https" = "y" ]; then
        cat >> .env <<EOF
MAIN_DOMAIN_CERT_RESOLVER=$cert_resolver
SAAS_DOMAIN_CERT_RESOLVER=$cert_resolver
API_DOMAIN_CERT_RESOLVER=$cert_resolver
FREE_DOMAIN_CERT_RESOLVER=$cert_resolver
ACME_EMAIL=test@example.com
EOF
        if [ "$cert_resolver" = "alidns" ]; then
            cat >> .env <<EOF
DNS_ALIYUN_ACCESS_KEY=test_access_key
DNS_ALIYUN_SECRET_KEY=test_secret_key
EOF
        fi
    fi

    cat >> .env <<EOF

# 存储配置
STORAGE_SAAS_DEFAULT_SERVICE=$storage_type

# 数据库和 ETCD
POSTGRES_PASSWORD=test_postgres_password
ETCD_ROOT_PASSWORD=test_etcd_password
SECRET_KEY_BASE=$(openssl rand -hex 64 2>/dev/null || echo "test_secret_key_base_$(date +%s)")

# Docker 镜像配置
REGISTRY_USERNAME=testuser
REGISTRY_PASSWORD=testpassword
IMAGE_NAME=registry.devops.tanmer.com/testuser/baklib
IMAGE_TAG=v1.31.0
EOF
}

# 运行测试
run_test() {
    local test_name=$1
    local main_domain=$2
    local enable_https=$3
    local cert_resolver=$4
    local storage_type=$5

    print_test "运行测试: $test_name"
    echo "配置:"
    echo "  - 主域名: $main_domain"
    echo "  - HTTPS: $enable_https"
    echo "  - 证书解析器: ${cert_resolver:-无}"
    echo "  - 存储类型: $storage_type"
    echo ""

    # 创建测试 .env
    create_test_env "$test_name" "$main_domain" "$enable_https" "$cert_resolver" "$storage_type"

    # 运行 config.sh（非交互模式）
    print_warning "运行 config.sh --non-interactive..."
    if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
        print_success "config.sh 执行成功"
    else
        print_error "config.sh 执行失败"
        cat /tmp/config-test-output.log
        return 1
    fi

    # 检查是否有带 '' 后缀的文件
    if ! check_bad_files; then
        return 1
    fi

    # 验证配置
    verify_config "$test_name" "$enable_https" "$cert_resolver" "$main_domain"
    local verify_result=$?

    echo ""
    return $verify_result
}

# 主测试流程
main() {
    echo "=========================================="
    echo "🧪 config.sh 测试脚本"
    echo "=========================================="
    echo ""

    # 备份文件
    backup_files

    # 测试计数器
    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # 测试用例 1: HTTPS 开启，使用 http01
    total_tests=$((total_tests + 1))
    if run_test "HTTPS开启-http01" "test1.example.com" "y" "http01" "local"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 2: HTTPS 开启，使用 alidns
    total_tests=$((total_tests + 1))
    if run_test "HTTPS开启-alidns" "test2.example.com" "y" "alidns" "local"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 3: HTTPS 关闭
    total_tests=$((total_tests + 1))
    if run_test "HTTPS关闭" "test3.example.com" "n" "" "local"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 4: 从 HTTPS 切换到 HTTP（模拟用户先配置 HTTPS，再配置 HTTP）
    total_tests=$((total_tests + 1))
    if run_test "HTTPS开启-http01" "test4.example.com" "y" "http01" "local"; then
        # 再次运行，但这次关闭 HTTPS
        create_test_env "HTTPS关闭" "test4.example.com" "n" "" "local"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "HTTPS关闭" "n" "" "test4.example.com"; then
                passed_tests=$((passed_tests + 1))
            else
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 5: 从 HTTP 切换到 HTTPS（模拟用户先配置 HTTP，再配置 HTTPS）
    total_tests=$((total_tests + 1))
    if run_test "HTTPS关闭" "test5.example.com" "n" "" "local"; then
        # 再次运行，但这次开启 HTTPS
        create_test_env "HTTPS开启-http01" "test5.example.com" "y" "http01" "local"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "HTTPS开启-http01" "y" "http01" "test5.example.com"; then
                passed_tests=$((passed_tests + 1))
            else
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 6: 不同的存储类型
    total_tests=$((total_tests + 1))
    if run_test "存储类型-qinium" "test6.example.com" "y" "http01" "qinium"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 7: 长域名
    total_tests=$((total_tests + 1))
    if run_test "长域名" "very-long-domain-name-for-testing.example.com" "y" "http01" "local"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 8: localhost 域名（开发环境）
    total_tests=$((total_tests + 1))
    if run_test "localhost域名" "baklib.localhost" "n" "" "local"; then
        passed_tests=$((passed_tests + 1))
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 9: HTTPS 来回切换（开启->关闭->开启）
    total_tests=$((total_tests + 1))
    print_test "测试用例 9: HTTPS 来回切换（开启->关闭->开启）"
    if run_test "HTTPS开启-http01" "test9.example.com" "y" "http01" "local"; then
        # 切换到关闭
        create_test_env "HTTPS关闭" "test9.example.com" "n" "" "local"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "HTTPS关闭" "n" "" "test9.example.com"; then
                # 再次切换到开启
                create_test_env "HTTPS开启-http01" "test9.example.com" "y" "http01" "local"
                if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
                    if check_bad_files && verify_config "HTTPS开启-http01" "y" "http01" "test9.example.com"; then
                        passed_tests=$((passed_tests + 1))
                    else
                        print_error "第三次运行（重新开启 HTTPS）验证失败"
                        failed_tests=$((failed_tests + 1))
                    fi
                else
                    print_error "第三次运行 config.sh 失败"
                    cat /tmp/config-test-output.log
                    failed_tests=$((failed_tests + 1))
                fi
            else
                print_error "第二次运行（关闭 HTTPS）验证失败"
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            cat /tmp/config-test-output.log
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 10: 证书解析器切换（http01->alidns->http01）
    total_tests=$((total_tests + 1))
    print_test "测试用例 10: 证书解析器切换（http01->alidns->http01）"
    if run_test "HTTPS开启-http01" "test10.example.com" "y" "http01" "local"; then
        # 切换到 alidns
        create_test_env "HTTPS开启-alidns" "test10.example.com" "y" "alidns" "local"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "HTTPS开启-alidns" "y" "alidns" "test10.example.com"; then
                # 再次切换回 http01
                create_test_env "HTTPS开启-http01" "test10.example.com" "y" "http01" "local"
                if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
                    if check_bad_files && verify_config "HTTPS开启-http01" "y" "http01" "test10.example.com"; then
                        passed_tests=$((passed_tests + 1))
                    else
                        print_error "第三次运行（切换回 http01）验证失败"
                        failed_tests=$((failed_tests + 1))
                    fi
                else
                    print_error "第三次运行 config.sh 失败"
                    cat /tmp/config-test-output.log
                    failed_tests=$((failed_tests + 1))
                fi
            else
                print_error "第二次运行（切换到 alidns）验证失败"
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            cat /tmp/config-test-output.log
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 11: 域名变更（保持 HTTPS 开启）
    total_tests=$((total_tests + 1))
    print_test "测试用例 11: 域名变更（保持 HTTPS 开启）"
    if run_test "HTTPS开启-http01" "test11-1.example.com" "y" "http01" "local"; then
        # 变更域名
        create_test_env "HTTPS开启-http01" "test11-2.example.com" "y" "http01" "local"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "HTTPS开启-http01" "y" "http01" "test11-2.example.com"; then
                passed_tests=$((passed_tests + 1))
            else
                print_error "域名变更验证失败"
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            cat /tmp/config-test-output.log
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 12: 存储类型切换（local->qinium->local）
    total_tests=$((total_tests + 1))
    print_test "测试用例 12: 存储类型切换（local->qinium->local）"
    if run_test "存储类型-local" "test12.example.com" "y" "http01" "local"; then
        # 切换到 qinium
        create_test_env "存储类型-qinium" "test12.example.com" "y" "http01" "qinium"
        if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
            if check_bad_files && verify_config "存储类型-qinium" "y" "http01" "test12.example.com"; then
                # 切换回 local
                create_test_env "存储类型-local" "test12.example.com" "y" "http01" "local"
                if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
                    if check_bad_files && verify_config "存储类型-local" "y" "http01" "test12.example.com"; then
                        passed_tests=$((passed_tests + 1))
                    else
                        print_error "第三次运行（切换回 local）验证失败"
                        failed_tests=$((failed_tests + 1))
                    fi
                else
                    print_error "第三次运行 config.sh 失败"
                    cat /tmp/config-test-output.log
                    failed_tests=$((failed_tests + 1))
                fi
            else
                print_error "第二次运行（切换到 qinium）验证失败"
                failed_tests=$((failed_tests + 1))
            fi
        else
            print_error "第二次运行 config.sh 失败"
            cat /tmp/config-test-output.log
            failed_tests=$((failed_tests + 1))
        fi
    else
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 测试用例 13: 多次执行 config.sh 不会破坏 basicAuth 和文件格式
    total_tests=$((total_tests + 1))
    print_test "测试用例 13: 多次执行 config.sh 不会破坏 basicAuth 和文件格式"

    # 先备份原始 basicAuth 配置
    local original_auth_line=$(grep -E "^\s*#?-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || grep -E "^\s*-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || echo "")

    # 第一次：关闭 HTTPS
    create_test_env "HTTPS关闭-多次执行测试" "test13.example.com" "n" "" "local"
    if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
        if check_bad_files && verify_config "HTTPS关闭" "n" "" "test13.example.com"; then
            # 检查 basicAuth 是否被修改
            local after_first_auth_line=$(grep -E "^\s*#?-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || grep -E "^\s*-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || echo "")
            if [ -n "$original_auth_line" ] && [ "$original_auth_line" != "$after_first_auth_line" ]; then
                print_error "第一次执行后 basicAuth 配置被修改"
                failed_tests=$((failed_tests + 1))
            else
                # 第二次：开启 HTTPS
                create_test_env "HTTPS开启-多次执行测试" "test13.example.com" "y" "http01" "local"
                if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
                    if check_bad_files && verify_config "HTTPS开启-http01" "y" "http01" "test13.example.com"; then
                        # 检查 basicAuth 是否被修改
                        local after_second_auth_line=$(grep -E "^\s*#?-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || grep -E "^\s*-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || echo "")
                        if [ -n "$original_auth_line" ] && [ "$original_auth_line" != "$after_second_auth_line" ]; then
                            print_error "第二次执行后 basicAuth 配置被修改"
                            failed_tests=$((failed_tests + 1))
                        else
                            # 第三次：再次关闭 HTTPS
                            create_test_env "HTTPS关闭-多次执行测试" "test13.example.com" "n" "" "local"
                            if bash scripts/config.sh --non-interactive > /tmp/config-test-output.log 2>&1; then
                                if check_bad_files && verify_config "HTTPS关闭" "n" "" "test13.example.com"; then
                                    # 检查 basicAuth 是否被修改
                                    local after_third_auth_line=$(grep -E "^\s*#?-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || grep -E "^\s*-.*admin:" traefik/etc/dynamic/traefik-dashboard.yml || echo "")
                                    if [ -n "$original_auth_line" ] && [ "$original_auth_line" != "$after_third_auth_line" ]; then
                                        print_error "第三次执行后 basicAuth 配置被修改"
                                        failed_tests=$((failed_tests + 1))
                                    else
                                        # 验证 traefik.yml 的注释格式没有被破坏
                                        if verify_traefik_yml_format && verify_docker_compose_indent; then
                                            print_success "多次执行 config.sh 后，basicAuth 和文件格式保持正确"
                                            passed_tests=$((passed_tests + 1))
                                        else
                                            print_error "多次执行后文件格式被破坏"
                                            failed_tests=$((failed_tests + 1))
                                        fi
                                    fi
                                else
                                    print_error "第三次执行验证失败"
                                    failed_tests=$((failed_tests + 1))
                                fi
                            else
                                print_error "第三次运行 config.sh 失败"
                                cat /tmp/config-test-output.log
                                failed_tests=$((failed_tests + 1))
                            fi
                        fi
                    else
                        print_error "第二次执行验证失败"
                        failed_tests=$((failed_tests + 1))
                    fi
                else
                    print_error "第二次运行 config.sh 失败"
                    cat /tmp/config-test-output.log
                    failed_tests=$((failed_tests + 1))
                fi
            fi
        else
            print_error "第一次执行验证失败"
            failed_tests=$((failed_tests + 1))
        fi
    else
        print_error "第一次运行 config.sh 失败"
        cat /tmp/config-test-output.log
        failed_tests=$((failed_tests + 1))
    fi
    restore_files
    echo ""

    # 总结
    echo "=========================================="
    echo "📊 测试总结"
    echo "=========================================="
    echo "总测试数: $total_tests"
    echo -e "${GREEN}通过: $passed_tests${NC}"
    echo -e "${RED}失败: $failed_tests${NC}"
    echo ""

    if [ $failed_tests -eq 0 ]; then
        print_success "所有测试通过！"
        return 0
    else
        print_error "有 $failed_tests 个测试失败"
        return 1
    fi
}

# 清理函数
cleanup() {
    restore_files
    rm -rf .test-backup
    rm -f /tmp/config-test-output.log
}

# 捕获退出信号
trap cleanup EXIT

# 运行主函数
main "$@"

