# frozen_string_literal: true

require 'securerandom'
require_relative '../logger'
require_relative '../project_root'
require_relative '../env_file'
require_relative '../render_yaml'
require_relative '../render_env'
require_relative '../config_draft'
require_relative '../ui'

module Baklib
  module Commands
    class ConfigRunner
      REGISTRY_SERVER = 'registry.devops.tanmer.com'

      def initialize(argv: [])
        @argv = argv
      end

      def run
        @non_interactive = ENV['NON_INTERACTIVE_MODE'].to_s == 'true' ||
                           @argv.include?('--non-interactive') ||
                           @argv.include?('-n')
        @ui = Ui.new(non_interactive: @non_interactive)
        @root = ProjectRoot.call
        Dir.chdir(@root)

        puts '=========================================='
        puts '⚙️  Baklib Docker Compose 配置'
        puts '(非交互模式：从 .env 读取)' if @non_interactive
        puts '=========================================='
        puts

        begin
          ensure_env_file

          if @non_interactive
            load_non_interactive
          else
            interactive
          end

          save_all
          ConfigDraft.clear(@root) unless @non_interactive
          render_and_validate
        rescue Interrupt
          # tty-prompt / tty-reader 在列表内按 Ctrl+C 会抛 TTY::Reader::InputInterrupt（Interrupt 子类），
          # 不会走 Signal.trap，若冒泡到 Rake 会打印整段堆栈
          puts
          puts '已取消配置（进度已保存在 .config.tmp，下次运行将自动填入）'
          exit 130
        end
      end

      private

      def persist_draft(updates)
        return if @non_interactive

        @draft ||= {}
        updates.each { |k, v| @draft[k.to_s] = v }
        ConfigDraft.save(@root, @draft)
      end

      def draft_str(key)
        return nil unless @draft

        v = @draft[key.to_s]
        return nil if v.nil?

        s = v.to_s.strip
        s.empty? ? nil : s
      end

      def draft_value(key, fallback)
        s = draft_str(key)
        s.nil? ? fallback : s
      end

      def draft_bool(key, fallback)
        return fallback unless @draft&.key?(key.to_s)

        v = @draft[key.to_s]
        case v
        when TrueClass then true
        when FalseClass then false
        when String then %w[y yes 1 true on].include?(v.downcase.strip)
        else false
        end
      end

      # 至少各含一个大写、小写、数字，共 10 位
      def random_password_10
        upper = ('A'..'Z').to_a
        lower = ('a'..'z').to_a
        digit = ('0'..'9').to_a
        pool = upper + lower + digit
        chars = [upper.sample, lower.sample, digit.sample] + Array.new(7) { pool.sample }
        chars.shuffle.join
      end

      def ensure_env_file
        env_path = File.join(@root, '.env')
        return if File.file?(env_path)

        defaults = RenderEnv.parse_defaults(@root)
        raise '缺少 templates/env_defaults.env，无法生成初始 .env' if defaults.empty?

        RenderEnv.write_dotenv(@root, defaults)
        Logger.success('已根据模板从 templates/env_defaults.env 生成初始 .env')
      end

      def load_non_interactive
        @main_domain = EnvFile.read_value('MAIN_DOMAIN')
        @saas = EnvFile.read_value('SAAS_DOMAIN_SUFFIX')
        @free = EnvFile.read_value('FREE_DOMAIN_SUFFIX')
        @cname = EnvFile.read_value('CNAME_DNS_SUFFIX')
        @is_local_trial = (@main_domain == 'baklib.localhost')
        if @is_local_trial
          sv = EnvFile.read_value('SHOW_VERIFICATION_CODE').strip
          @show_verification = sv.empty? ? 'y' : sv
          ip = EnvFile.read_value('INGRESS_PROTOCOL').strip
          @ingress_protocol = ip.empty? ? 'http' : ip
          po = EnvFile.read_value('INGRESS_PORT').strip
          @ingress_port = po.empty? ? '80' : po
        end

        cr = EnvFile.read_value('MAIN_DOMAIN_CERT_RESOLVER')
        if cr != ''
          @main_cert = cr
          @saas_cert = EnvFile.read_value('SAAS_DOMAIN_CERT_RESOLVER')
          @api_cert = EnvFile.read_value('API_DOMAIN_CERT_RESOLVER')
          @free_cert = EnvFile.read_value('FREE_DOMAIN_CERT_RESOLVER')
          @dns_ak = EnvFile.read_value('DNS_ALIYUN_ACCESS_KEY')
          @dns_sk = EnvFile.read_value('DNS_ALIYUN_SECRET_KEY')
          @acme_email = EnvFile.read_value('ACME_EMAIL')
        else
          @main_cert = @saas_cert = @api_cert = @free_cert = ''
          @dns_ak = @dns_sk = @acme_email = ''
        end

        @external_ip = EnvFile.read_value('EXTERNAL_IP')
        @pg_pass = EnvFile.read_value('POSTGRES_PASSWORD')
        @etcd_pass = EnvFile.read_value('ETCD_ROOT_PASSWORD')
        @secret_key = EnvFile.read_value('SECRET_KEY_BASE')
        @admin_phone = EnvFile.read_value('ADMIN_PHONE')

        s = EnvFile.read_value('STORAGE_SAAS_DEFAULT_SERVICE').strip
        @storage = s.empty? ? 'local' : s
        load_storage_from_env
        validate_aliyun_storage_required! if @storage == 'aliyun'

        @registry_user = EnvFile.read_value('REGISTRY_USERNAME')
        @registry_pass = EnvFile.read_value('REGISTRY_PASSWORD')
        @image_name = EnvFile.read_value('IMAGE_NAME')
        @image_tag = EnvFile.read_value('IMAGE_TAG')

        @tls_v12 = truthy_env_str?(EnvFile.read_value('TRAEFIK_TLS_ENABLE_12'), default: true)
        @tls_v13 = truthy_env_str?(EnvFile.read_value('TRAEFIK_TLS_ENABLE_13'), default: true)
        if !@tls_v12 && !@tls_v13
          Logger.warning('TRAEFIK_TLS_ENABLE_12 与 TRAEFIK_TLS_ENABLE_13 不能同时为否，已改为同时启用 TLS 1.2 与 1.3')
          @tls_v12 = true
          @tls_v13 = true
        end

        Logger.success('已从 .env 文件读取配置')
        puts
      end

      def load_storage_from_env
        case @storage
        when 'qinium'
          @st_qiniu_ak = EnvFile.read_value('STORAGE_QINIU_ACCESS_KEY')
          @st_qiniu_sk = EnvFile.read_value('STORAGE_QINIU_SECRET_KEY')
          @st_qiniu_bucket = EnvFile.read_value('STORAGE_QINIU_BUCKET')
          @st_qiniu_proto = EnvFile.read_value('STORAGE_QINIU_PROTOCOL')
          @st_qiniu_domain = EnvFile.read_value('STORAGE_QINIU_DOMAIN')
        when 'aliyun'
          @st_ali_ak = EnvFile.read_value('STORAGE_ALIYUN_ACCESS_KEY')
          @st_ali_sk = EnvFile.read_value('STORAGE_ALIYUN_SECRET_KEY')
          @st_ali_bucket = EnvFile.read_value('STORAGE_ALIYUN_BUCKET')
          @st_ali_ep = EnvFile.read_value('STORAGE_ALIYUN_ENDPOINT')
          @st_ali_cdn_h = EnvFile.read_value('STORAGE_ALIYUN_CDN_HOST')
          @st_ali_cdn_k = EnvFile.read_value('STORAGE_ALIYUN_CDN_KEY')
          @st_ali_pub = EnvFile.read_value('STORAGE_ALIYUN_PUBLIC')
        when 'amazon'
          @st_aws_ak = EnvFile.read_value('STORAGE_AWS_ACCESS_KEY')
          @st_aws_sk = EnvFile.read_value('STORAGE_AWS_SECRET_KEY')
          @st_aws_bucket = EnvFile.read_value('STORAGE_AWS_BUCKET')
          @st_aws_region = EnvFile.read_value('STORAGE_AWS_REGION')
          @st_aws_pub = EnvFile.read_value('STORAGE_AWS_PUBLIC')
          @st_aws_exp = EnvFile.read_value('STORAGE_AWS_EXPIRES_IN')
          @st_aws_cdn = EnvFile.read_value('STORAGE_AWS_CDN_HOST')
          @st_aws_pkid = EnvFile.read_value('STORAGE_AWS_CDN_PUBLIC_KEY_ID')
          @st_aws_pkb64 = EnvFile.read_value('STORAGE_AWS_CDN_PRIVATE_KEY_BASE64')
        end
      end

      def interactive
        @draft = ConfigDraft.load(@root)
        unless @draft.empty?
          Logger.info('已载入上次未完成的配置草稿（.config.tmp），将用作各步骤默认值')
          puts
        end
        ui = @ui
        cur_main = draft_value('MAIN_DOMAIN', EnvFile.read_value('MAIN_DOMAIN'))
        @main_domain = ui.ask('MAIN_DOMAIN', '主域名', default: cur_main)
        persist_draft('MAIN_DOMAIN' => @main_domain)
        @is_local_trial = (@main_domain == 'baklib.localhost')

        if @is_local_trial
          Logger.info('检测到本地试用环境 (baklib.localhost)，自动配置本地环境参数...')
          @show_verification = 'y'
          @ingress_protocol = 'http'
          @ingress_port = '80'
          @main_cert = @saas_cert = @api_cert = @free_cert = ''
          @dns_ak = @dns_sk = @acme_email = ''
          Logger.success('已自动设置：SHOW_VERIFICATION_CODE=y, INGRESS_PROTOCOL=http, INGRESS_PORT=80, HTTPS=关闭')
          puts
        end

        ex_saas = @main_domain.strip.empty? ? '.example.com' : ".#{@main_domain}"
        ex_free = @main_domain.strip.empty? ? '.apps.example.com' : ".apps.#{@main_domain}"
        ex_cname = @main_domain.strip.empty? ? '.cname.example.com' : ".cname.#{@main_domain}"

        # 默认值随当前主域名推导；显式传 default，避免仍显示 .env 里旧主域下的后缀
        @saas = ui.ask('SAAS_DOMAIN_SUFFIX', '组织域名后缀', default: draft_value('SAAS_DOMAIN_SUFFIX', ex_saas))
        persist_draft('SAAS_DOMAIN_SUFFIX' => @saas)
        @free = ui.ask('FREE_DOMAIN_SUFFIX', '站点域名后缀', default: draft_value('FREE_DOMAIN_SUFFIX', ex_free))
        persist_draft('FREE_DOMAIN_SUFFIX' => @free)
        @cname = ui.ask('CNAME_DNS_SUFFIX', 'CNAME 域名后缀', default: draft_value('CNAME_DNS_SUFFIX', ex_cname))
        persist_draft('CNAME_DNS_SUFFIX' => @cname)

        puts
        puts '=========================================='
        puts '🔒 HTTPS 配置'
        puts '=========================================='
        puts

        unless @is_local_trial
          existing = EnvFile.read_value('MAIN_DOMAIN_CERT_RESOLVER')
          # 每次均询问；默认与当前 .env 一致：已配置证书解析器则默认为是，否则为否（.config.tmp 草稿优先）
          https_default = draft_bool('_bool_open_https', existing != '')
          if ui.yes?('是否开启 HTTPS？', default: https_default)
            persist_draft('_bool_open_https' => true)
            configure_https_certs
          else
            persist_draft('_bool_open_https' => false)
            @main_cert = @saas_cert = @api_cert = @free_cert = ''
            @dns_ak = @dns_sk = @acme_email = ''
          end
        end

        if @is_local_trial
          @tls_v12 = true
          @tls_v13 = true
        else
          puts
          puts '=========================================='
          puts '🔐 Traefik TLS 版本（HTTPS 入口）'
          puts '=========================================='
          puts
          preset = ui.choose(
            'HTTPS 入口支持的 TLS 协议版本（将写入 traefik/etc/dynamic/sni-strict.yml）',
            [
              ['both', 'TLS 1.2 与 1.3（推荐，兼容常见客户端）'],
              ['tls13_only', '仅 TLS 1.3（更安全，旧客户端可能无法连接）'],
              ['tls12_only', '仅 TLS 1.2（不推荐，仅极旧环境）']
            ],
            default: tls_preset_default
          )
          apply_tls_preset(preset)
          persist_draft(
            '_tls_preset' => preset,
            'TRAEFIK_TLS_ENABLE_12' => (@tls_v12 ? 'y' : 'n'),
            'TRAEFIK_TLS_ENABLE_13' => (@tls_v13 ? 'y' : 'n')
          )
        end

        puts
        puts '=========================================='
        puts '💾 存储配置'
        puts '=========================================='
        puts

        storage_default = draft_str('STORAGE_SAAS_DEFAULT_SERVICE')
        storage_default = EnvFile.read_value('STORAGE_SAAS_DEFAULT_SERVICE').strip if storage_default.nil?
        storage_default = 'local' if storage_default.empty?

        @storage = ui.choose(
          '存储类型',
          [
            %w[local 本地存储],
            %w[qinium 七牛云],
            %w[aliyun 阿里云 OSS],
            %w[amazon AWS S3]
          ],
          default: storage_default
        )
        persist_draft('STORAGE_SAAS_DEFAULT_SERVICE' => @storage)

        case @storage
        when 'qinium'
          Logger.info('配置七牛云存储')
          @st_qiniu_ak = ui.ask('STORAGE_QINIU_ACCESS_KEY', '七牛云 Access Key', default: draft_value('STORAGE_QINIU_ACCESS_KEY', EnvFile.read_value('STORAGE_QINIU_ACCESS_KEY')))
          persist_draft('STORAGE_QINIU_ACCESS_KEY' => @st_qiniu_ak)
          @st_qiniu_sk = ui.ask('STORAGE_QINIU_SECRET_KEY', '七牛云 Secret Key', default: draft_value('STORAGE_QINIU_SECRET_KEY', EnvFile.read_value('STORAGE_QINIU_SECRET_KEY')))
          persist_draft('STORAGE_QINIU_SECRET_KEY' => @st_qiniu_sk)
          @st_qiniu_bucket = ui.ask('STORAGE_QINIU_BUCKET', '七牛云 Bucket 名称', default: draft_value('STORAGE_QINIU_BUCKET', EnvFile.read_value('STORAGE_QINIU_BUCKET')))
          persist_draft('STORAGE_QINIU_BUCKET' => @st_qiniu_bucket)
          @st_qiniu_proto = ui.choose(
            '七牛云协议',
            [
              ['https', 'HTTPS（推荐）'],
              ['http', 'HTTP']
            ],
            default: storage_qiniu_protocol_default
          )
          persist_draft('STORAGE_QINIU_PROTOCOL' => @st_qiniu_proto)
          @st_qiniu_domain = ui.ask('STORAGE_QINIU_DOMAIN', '七牛云域名', default: draft_value('STORAGE_QINIU_DOMAIN', EnvFile.read_value('STORAGE_QINIU_DOMAIN')))
          persist_draft('STORAGE_QINIU_DOMAIN' => @st_qiniu_domain)
        when 'aliyun'
          Logger.info('配置阿里云 OSS')
          @st_ali_ak = ui.ask('STORAGE_ALIYUN_ACCESS_KEY', '阿里云 Access Key ID', default: draft_value('STORAGE_ALIYUN_ACCESS_KEY', EnvFile.read_value('STORAGE_ALIYUN_ACCESS_KEY')))
          persist_draft('STORAGE_ALIYUN_ACCESS_KEY' => @st_ali_ak)
          @st_ali_sk = ui.ask('STORAGE_ALIYUN_SECRET_KEY', '阿里云 Access Key Secret', default: draft_value('STORAGE_ALIYUN_SECRET_KEY', EnvFile.read_value('STORAGE_ALIYUN_SECRET_KEY')))
          persist_draft('STORAGE_ALIYUN_SECRET_KEY' => @st_ali_sk)
          @st_ali_bucket = ui.ask('STORAGE_ALIYUN_BUCKET', '阿里云 OSS Bucket', default: draft_value('STORAGE_ALIYUN_BUCKET', EnvFile.read_value('STORAGE_ALIYUN_BUCKET')))
          persist_draft('STORAGE_ALIYUN_BUCKET' => @st_ali_bucket)
          @st_ali_ep = ask_required_trimmed(ui, 'STORAGE_ALIYUN_ENDPOINT', '阿里云 OSS Endpoint')
          persist_draft('STORAGE_ALIYUN_ENDPOINT' => @st_ali_ep)
          @st_ali_cdn_h = ask_required_trimmed(ui, 'STORAGE_ALIYUN_CDN_HOST', '阿里云 CDN 域名')
          persist_draft('STORAGE_ALIYUN_CDN_HOST' => @st_ali_cdn_h)
          @st_ali_pub = ui.choose(
            '是否公开访问（Bucket 读权限）',
            [
              ['true', '是（公开）'],
              ['false', '否（私有）']
            ],
            default: storage_aliyun_public_choose_default
          )
          persist_draft('STORAGE_ALIYUN_PUBLIC' => @st_ali_pub)
          if @st_ali_pub == 'false'
            @st_ali_cdn_k = ask_required_trimmed(ui, 'STORAGE_ALIYUN_CDN_KEY', '阿里云 CDN Key')
            persist_draft('STORAGE_ALIYUN_CDN_KEY' => @st_ali_cdn_k)
          else
            @st_ali_cdn_k = ''
            persist_draft('STORAGE_ALIYUN_CDN_KEY' => '')
          end
        when 'amazon'
          Logger.info('配置 AWS S3')
          @st_aws_ak = ui.ask('STORAGE_AWS_ACCESS_KEY', 'AWS Access Key ID', default: draft_value('STORAGE_AWS_ACCESS_KEY', EnvFile.read_value('STORAGE_AWS_ACCESS_KEY')))
          persist_draft('STORAGE_AWS_ACCESS_KEY' => @st_aws_ak)
          @st_aws_sk = ui.ask('STORAGE_AWS_SECRET_KEY', 'AWS Secret Access Key', default: draft_value('STORAGE_AWS_SECRET_KEY', EnvFile.read_value('STORAGE_AWS_SECRET_KEY')))
          persist_draft('STORAGE_AWS_SECRET_KEY' => @st_aws_sk)
          @st_aws_bucket = ui.ask('STORAGE_AWS_BUCKET', 'AWS S3 Bucket', default: draft_value('STORAGE_AWS_BUCKET', EnvFile.read_value('STORAGE_AWS_BUCKET')))
          persist_draft('STORAGE_AWS_BUCKET' => @st_aws_bucket)
          @st_aws_region = ui.ask('STORAGE_AWS_REGION', 'AWS 区域', default: draft_value('STORAGE_AWS_REGION', EnvFile.read_value('STORAGE_AWS_REGION')))
          persist_draft('STORAGE_AWS_REGION' => @st_aws_region)
          @st_aws_pub = ui.choose(
            '是否公开访问（Bucket/Object）',
            [
              ['true', '是（公开）'],
              ['false', '否（私有）']
            ],
            default: storage_public_env_default('STORAGE_AWS_PUBLIC')
          )
          persist_draft('STORAGE_AWS_PUBLIC' => @st_aws_pub)
          @st_aws_exp = ui.ask('STORAGE_AWS_EXPIRES_IN', '签名过期时间（秒）', default: draft_value('STORAGE_AWS_EXPIRES_IN', EnvFile.read_value('STORAGE_AWS_EXPIRES_IN')))
          @st_aws_exp = '3600' if @st_aws_exp.strip.empty?
          persist_draft('STORAGE_AWS_EXPIRES_IN' => @st_aws_exp)
          @st_aws_cdn = ui.ask('STORAGE_AWS_CDN_HOST', 'CloudFront 域名（可选）', default: draft_value('STORAGE_AWS_CDN_HOST', EnvFile.read_value('STORAGE_AWS_CDN_HOST')))
          persist_draft('STORAGE_AWS_CDN_HOST' => @st_aws_cdn)
          @st_aws_pkid = ui.ask('STORAGE_AWS_CDN_PUBLIC_KEY_ID', 'Public Key ID（可选）', default: draft_value('STORAGE_AWS_CDN_PUBLIC_KEY_ID', EnvFile.read_value('STORAGE_AWS_CDN_PUBLIC_KEY_ID')))
          persist_draft('STORAGE_AWS_CDN_PUBLIC_KEY_ID' => @st_aws_pkid)
          @st_aws_pkb64 = ui.ask('STORAGE_AWS_CDN_PRIVATE_KEY_BASE64', 'Private Key Base64（可选）', default: draft_value('STORAGE_AWS_CDN_PRIVATE_KEY_BASE64', EnvFile.read_value('STORAGE_AWS_CDN_PRIVATE_KEY_BASE64')))
          persist_draft('STORAGE_AWS_CDN_PRIVATE_KEY_BASE64' => @st_aws_pkb64)
        end

        puts
        puts '=========================================='
        puts '📧 其他重要配置'
        puts '=========================================='
        puts

        @external_ip = ui.ask('EXTERNAL_IP', '服务器外部 IP 地址', default: draft_value('EXTERNAL_IP', EnvFile.read_value('EXTERNAL_IP')))
        persist_draft('EXTERNAL_IP' => @external_ip)
        @pg_pass = ask_password_or_generate(
          ui,
          'POSTGRES_PASSWORD',
          'PostgreSQL 数据库密码'
        )
        persist_draft('POSTGRES_PASSWORD' => @pg_pass)

        @etcd_pass = ask_password_or_generate(
          ui,
          'ETCD_ROOT_PASSWORD',
          'ETCD Root 密码'
        )
        persist_draft('ETCD_ROOT_PASSWORD' => @etcd_pass)

        puts
        Logger.info('管理员账号（首个用户登录手机号，install 时将写入数据库）')
        @admin_phone = ui.ask('ADMIN_PHONE', '管理员手机号', default: draft_value('ADMIN_PHONE', EnvFile.read_value('ADMIN_PHONE')))
        persist_draft('ADMIN_PHONE' => @admin_phone)

        puts
        Logger.info('生成 SECRET_KEY_BASE...')
        sk_default = draft_value('SECRET_KEY_BASE', EnvFile.read_value('SECRET_KEY_BASE'))
        if sk_default.empty?
          @secret_key = SecureRandom.hex(64)
          Logger.success('已自动生成 SECRET_KEY_BASE')
        else
          @secret_key = sk_default
          Logger.info('使用现有的 SECRET_KEY_BASE')
        end
        persist_draft('SECRET_KEY_BASE' => @secret_key)

        puts
        puts '=========================================='
        puts '🔐 Docker 镜像仓库认证'
        puts '=========================================='
        puts

        Logger.info("Docker 镜像仓库地址: #{REGISTRY_SERVER} (固定)")

        reg_u = EnvFile.read_value('REGISTRY_USERNAME')
        img_d = EnvFile.read_value('IMAGE_NAME')
        if reg_u.empty? && !img_d.empty? && img_d.start_with?("#{REGISTRY_SERVER}/")
          reg_u = img_d.sub(/\A#{Regexp.escape(REGISTRY_SERVER)}\//, '').split('/').first.to_s
        end

        @registry_user = ui.ask('REGISTRY_USERNAME', 'Docker 镜像仓库用户名（账户名）', default: draft_value('REGISTRY_USERNAME', reg_u))
        persist_draft('REGISTRY_USERNAME' => @registry_user)
        rp_default = draft_str('REGISTRY_PASSWORD') || EnvFile.read_value('REGISTRY_PASSWORD')
        @registry_pass = ui.mask('REGISTRY_PASSWORD', 'Docker 镜像仓库密码', default: rp_default)
        persist_draft('REGISTRY_PASSWORD' => @registry_pass)

        puts
        @image_name = ui.ask('IMAGE_NAME', 'Docker 镜像完整路径', default: draft_value('IMAGE_NAME', EnvFile.read_value('IMAGE_NAME')))
        persist_draft('IMAGE_NAME' => @image_name)
        @image_tag = ui.ask('IMAGE_TAG', 'Docker 镜像标签', default: draft_value('IMAGE_TAG', EnvFile.read_value('IMAGE_TAG')))
        persist_draft('IMAGE_TAG' => @image_tag)
      end

      def storage_qiniu_protocol_default
        dv = draft_str('STORAGE_QINIU_PROTOCOL')
        if dv && %w[http https].include?(dv.downcase)
          return dv.downcase
        end

        v = EnvFile.read_value('STORAGE_QINIU_PROTOCOL').strip.downcase
        return 'https' if v.empty?

        %w[http https].include?(v) ? v : 'https'
      end

      def storage_public_env_default(key)
        dv = draft_str(key)
        return dv if %w[true false].include?(dv.to_s.strip.downcase)

        truthy_env_str?(EnvFile.read_value(key), default: false) ? 'true' : 'false'
      end

      # 向导中「是否公开」：无草稿/无 .env 时默认私有（与七牛/AWS 的 env 默认语义区分）
      def storage_aliyun_public_choose_default
        dv = draft_str('STORAGE_ALIYUN_PUBLIC')
        return dv if %w[true false].include?(dv.to_s.strip.downcase)

        ev = EnvFile.read_value('STORAGE_ALIYUN_PUBLIC').to_s.strip.downcase
        return 'true' if %w[true 1 yes y on].include?(ev)
        return 'false' if %w[false 0 no n off].include?(ev)

        'false'
      end

      def ask_required_trimmed(ui, env_key, label)
        default = draft_value(env_key, EnvFile.read_value(env_key))
        loop do
          v = ui.ask(env_key, "#{label}（必填）", default: default)
          s = v.to_s.strip
          return s unless s.empty?

          Logger.warning("#{label} 不能为空，请重新填写")
        end
      end

      # 有草稿/.env 时沿用；仅二者皆空时回车才生成随机密码（避免二次 config 重置生产密码）
      def ask_password_or_generate(ui, env_key, label)
        existing = draft_str(env_key) || EnvFile.read_value(env_key).to_s.strip
        existing = nil if existing.to_s.empty?
        hint = if existing
                 "#{label}（直接回车保持现有密码）"
               else
                 "#{label}（直接回车将生成随机 10 位）"
               end
        v = ui.ask(env_key, hint, default: existing || '')
        s = v.to_s.strip
        return s unless s.empty?
        return existing if existing

        generated = random_password_10
        Logger.success("已自动生成 #{label}（10 位，含大小写字母与数字）")
        generated
      end

      def validate_aliyun_storage_required!
        missing = []
        missing << 'STORAGE_ALIYUN_ENDPOINT' if @st_ali_ep.to_s.strip.empty?
        missing << 'STORAGE_ALIYUN_CDN_HOST' if @st_ali_cdn_h.to_s.strip.empty?
        pub = @st_ali_pub.to_s.strip.downcase
        private_bucket = %w[false 0 no n off].include?(pub) || pub.empty?
        if private_bucket && @st_ali_cdn_k.to_s.strip.empty?
          missing << 'STORAGE_ALIYUN_CDN_KEY（私有 Bucket 必填）'
        end
        return if missing.empty?

        Logger.error("阿里云 OSS 配置不完整，缺少: #{missing.join(', ')}")
        exit 1
      end

      def tls_preset_default
        p = draft_str('_tls_preset')
        return p if %w[both tls13_only tls12_only].include?(p.to_s)

        v12 = truthy_env_str?(draft_value('TRAEFIK_TLS_ENABLE_12', EnvFile.read_value('TRAEFIK_TLS_ENABLE_12')), default: true)
        v13 = truthy_env_str?(draft_value('TRAEFIK_TLS_ENABLE_13', EnvFile.read_value('TRAEFIK_TLS_ENABLE_13')), default: true)
        return 'both' if v12 && v13
        return 'tls13_only' if v13 && !v12
        return 'tls12_only' if v12 && !v13

        'both'
      end

      def https_cert_method_default
        d = draft_str('_https_cert_method')
        return d if %w[http01 alidns].include?(d.to_s)

        EnvFile.read_value('MAIN_DOMAIN_CERT_RESOLVER') == 'alidns' ? 'alidns' : 'http01'
      end

      def apply_tls_preset(preset)
        case preset.to_s
        when 'tls13_only'
          @tls_v12 = false
          @tls_v13 = true
        when 'tls12_only'
          @tls_v12 = true
          @tls_v13 = false
        else
          @tls_v12 = true
          @tls_v13 = true
        end
      end

      def truthy_env_str?(str, default:)
        s = str.to_s.strip.downcase
        return default if s.empty?

        %w[y yes 1 true on].include?(s)
      end

      def configure_https_certs
        ui = @ui
        method = ui.choose(
          'HTTPS 证书签发方式',
          [
            ['http01', 'HTTP-01 挑战（需开放 80）'],
            ['alidns', 'DNS-01 挑战（阿里云 DNS）']
          ],
          default: https_cert_method_default
        )
        persist_draft('_https_cert_method' => method)
        if method == 'alidns'
          @main_cert = @saas_cert = @api_cert = @free_cert = 'alidns'
          puts
          Logger.info('配置阿里云 DNS（用于 DNS-01）')
          @dns_ak = ui.ask('DNS_ALIYUN_ACCESS_KEY', '阿里云 Access Key ID', default: draft_value('DNS_ALIYUN_ACCESS_KEY', EnvFile.read_value('DNS_ALIYUN_ACCESS_KEY')))
          persist_draft('DNS_ALIYUN_ACCESS_KEY' => @dns_ak)
          @dns_sk = ui.ask('DNS_ALIYUN_SECRET_KEY', '阿里云 Access Key Secret', default: draft_value('DNS_ALIYUN_SECRET_KEY', EnvFile.read_value('DNS_ALIYUN_SECRET_KEY')))
          persist_draft('DNS_ALIYUN_SECRET_KEY' => @dns_sk)
        else
          @main_cert = @saas_cert = @api_cert = @free_cert = 'http01'
          @dns_ak = @dns_sk = ''
          persist_draft('DNS_ALIYUN_ACCESS_KEY' => '', 'DNS_ALIYUN_SECRET_KEY' => '')
        end
        puts
        @acme_email = ui.ask('ACME_EMAIL', "ACME 证书邮箱（Let's Encrypt 通知）", default: draft_value('ACME_EMAIL', EnvFile.read_value('ACME_EMAIL')))
        @acme_email = 'acme-your-email@example.com' if @acme_email.strip.empty?
        persist_draft(
          'MAIN_DOMAIN_CERT_RESOLVER' => @main_cert,
          'ACME_EMAIL' => @acme_email
        )
      end

      def build_merged_env
        defaults = RenderEnv.parse_defaults(@root)
        env_path = File.join(@root, '.env')
        existing = File.file?(env_path) ? Dotenv.parse(env_path).transform_values { |v| v.nil? ? '' : v.to_s } : {}
        merged = defaults.merge(existing).merge(wizard_env_overrides)
        apply_https_cleanup!(merged)
        merged
      end

      def apply_https_cleanup!(merged)
        return if @main_cert.to_s != ''

        %w[MAIN_DOMAIN_CERT_RESOLVER SAAS_DOMAIN_CERT_RESOLVER API_DOMAIN_CERT_RESOLVER FREE_DOMAIN_CERT_RESOLVER ACME_EMAIL].each do |k|
          merged.delete(k)
        end
      end

      def wizard_env_overrides
        h = {
          'MAIN_DOMAIN' => @main_domain.to_s,
          'SAAS_DOMAIN_SUFFIX' => @saas.to_s,
          'FREE_DOMAIN_SUFFIX' => @free.to_s,
          'CNAME_DNS_SUFFIX' => @cname.to_s,
          'DNS_ALIYUN_ACCESS_KEY' => @dns_ak.to_s,
          'DNS_ALIYUN_SECRET_KEY' => @dns_sk.to_s,
          'STORAGE_SAAS_DEFAULT_SERVICE' => @storage.to_s,
          'EXTERNAL_IP' => @external_ip.to_s,
          'POSTGRES_PASSWORD' => @pg_pass.to_s,
          'ETCD_ROOT_PASSWORD' => @etcd_pass.to_s,
          'SECRET_KEY_BASE' => @secret_key.to_s,
          'ADMIN_PHONE' => @admin_phone.to_s,
          'REGISTRY_USERNAME' => @registry_user.to_s,
          'REGISTRY_PASSWORD' => @registry_pass.to_s,
          'IMAGE_NAME' => @image_name.to_s,
          'IMAGE_TAG' => @image_tag.to_s,
          'TRAEFIK_TLS_ENABLE_12' => (@tls_v12 ? 'y' : 'n'),
          'TRAEFIK_TLS_ENABLE_13' => (@tls_v13 ? 'y' : 'n')
        }

        if @is_local_trial
          h['SHOW_VERIFICATION_CODE'] = @show_verification.to_s
          h['INGRESS_PROTOCOL'] = @ingress_protocol.to_s
          h['INGRESS_PORT'] = @ingress_port.to_s
        end

        if @main_cert.to_s != ''
          h['MAIN_DOMAIN_CERT_RESOLVER'] = @main_cert.to_s
          h['SAAS_DOMAIN_CERT_RESOLVER'] = @saas_cert.to_s
          h['API_DOMAIN_CERT_RESOLVER'] = @api_cert.to_s
          h['FREE_DOMAIN_CERT_RESOLVER'] = @free_cert.to_s
        end

        h['ACME_EMAIL'] = @acme_email.to_s if @acme_email.to_s != ''

        case @storage
        when 'qinium'
          h.merge!(
            'STORAGE_QINIU_ACCESS_KEY' => @st_qiniu_ak.to_s,
            'STORAGE_QINIU_SECRET_KEY' => @st_qiniu_sk.to_s,
            'STORAGE_QINIU_BUCKET' => @st_qiniu_bucket.to_s,
            'STORAGE_QINIU_PROTOCOL' => @st_qiniu_proto.to_s,
            'STORAGE_QINIU_DOMAIN' => @st_qiniu_domain.to_s
          )
        when 'aliyun'
          h.merge!(
            'STORAGE_ALIYUN_ACCESS_KEY' => @st_ali_ak.to_s,
            'STORAGE_ALIYUN_SECRET_KEY' => @st_ali_sk.to_s,
            'STORAGE_ALIYUN_BUCKET' => @st_ali_bucket.to_s,
            'STORAGE_ALIYUN_ENDPOINT' => @st_ali_ep.to_s,
            'STORAGE_ALIYUN_CDN_HOST' => @st_ali_cdn_h.to_s,
            'STORAGE_ALIYUN_CDN_KEY' => @st_ali_cdn_k.to_s,
            'STORAGE_ALIYUN_PUBLIC' => @st_ali_pub.to_s
          )
        when 'amazon'
          h.merge!(
            'STORAGE_AWS_ACCESS_KEY' => @st_aws_ak.to_s,
            'STORAGE_AWS_SECRET_KEY' => @st_aws_sk.to_s,
            'STORAGE_AWS_BUCKET' => @st_aws_bucket.to_s,
            'STORAGE_AWS_REGION' => @st_aws_region.to_s,
            'STORAGE_AWS_PUBLIC' => @st_aws_pub.to_s,
            'STORAGE_AWS_EXPIRES_IN' => @st_aws_exp.to_s,
            'STORAGE_AWS_CDN_HOST' => @st_aws_cdn.to_s,
            'STORAGE_AWS_CDN_PUBLIC_KEY_ID' => @st_aws_pkid.to_s,
            'STORAGE_AWS_CDN_PRIVATE_KEY_BASE64' => @st_aws_pkb64.to_s
          )
        end

        h
      end

      def save_all
        puts
        puts '=========================================='
        puts '💾 保存配置到 .env（templates/.env.erb）'
        puts '=========================================='
        puts

        merged = build_merged_env
        RenderEnv.write_dotenv(@root, merged)

        Logger.success('配置已保存到 .env 文件')
        puts
      end

      def render_and_validate
        puts '=========================================='
        puts '渲染 Traefik / Compose YAML（.yml.erb → .yml）'
        puts '=========================================='
        puts

        RenderYaml.render(@root)

        Logger.success('Traefik / Compose 配置已更新')
        puts

        Logger.info('检查必要的文件...')
        Logger.warning('product.pem 不存在') unless File.file?(File.join(@root, 'product.pem'))
        Logger.warning('templates/traefik/etc/traefik.yml.erb 模板不存在') unless File.file?(File.join(@root, 'templates/traefik/etc/traefik.yml.erb'))
        Logger.warning('traefik/etc/traefik.yml 未生成') unless File.file?(File.join(@root, 'traefik/etc/traefik.yml'))
        puts

        Logger.info('验证 .env 文件语法...')
        exit 1 unless EnvFile.validate(File.join(@root, '.env'))

        Logger.success('.env 文件语法检查通过')
        puts
      end
    end

    module Config
      module_function

      def run(argv: [])
        ConfigRunner.new(argv: argv).run
      end
    end
  end
end
