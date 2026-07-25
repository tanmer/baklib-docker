# frozen_string_literal: true

require 'erb'
require 'dotenv'
require_relative 'env_file'
require_relative 'project_root'

module Baklib
  # 从 templates/.env.erb 渲染根目录 .env（与 YAML 模板同一套思路）
  #
  # 格式一律在模板 + ERB 内决定，不对渲染结果做二次替换。
  #
  # ERB 短横线（与 Rails 视图相同语义，见 Ruby stdlib ERB）：
  # - `ERB.new(..., trim_mode: '-')` 开启 trim 模式后，
  #   `-%>` 会去掉**模板里**紧跟在该标签后的换行（以及行尾空白）；
  #   `<%-` 会去掉**模板里**该标签前的换行（以及行首空白）。
  # - 这样「空 `<%= ls(...) -%>`」不会额外输出一行空行；有值时由 `ls` 返回的 `"KEY=val\n"` 仍带行尾换行。
  # - 参考：Ruby ERB 文档中 `trim_mode`、Rails `ActionView::Template` 对 ERB 的默认 trim 配置。
  module RenderEnv
    DEFAULTS_REL = 'templates/env_defaults.env'
    TEMPLATE_REL = 'templates/.env.erb'

    module_function

    def parse_defaults(root)
      path = File.join(root, DEFAULTS_REL)
      return {} unless File.file?(path)

      Dotenv.parse(path).transform_values { |v| v.nil? ? '' : v.to_s }
    end

    def render_string(root, merged_hash)
      tmpl = File.join(root, TEMPLATE_REL)
      raise "缺少模板 #{TEMPLATE_REL}，请确认已克隆完整仓库" unless File.file?(tmpl)

      ctx = EnvErbContext.new(merged_hash)
      erb = ERB.new(File.read(tmpl, encoding: 'UTF-8'), trim_mode: '-')
      erb.result(ctx.binding_for_erb)
    end

    def write_file(root, relative_path, merged_hash)
      out = File.join(root, relative_path)
      body = render_string(root, merged_hash)
      File.write(out, body, encoding: 'UTF-8')
    end

    # 根目录 .env
    def write_dotenv(root, merged_hash)
      write_file(root, '.env', merged_hash)
    end

    # ERB 绑定：templates/.env.erb 中可用 ls、https_enabled?、storage_hint、saas_storage_*?、sentry_vars_present?、github_proxy_present? 等
    class EnvErbContext
      def initialize(vars)
        @vars = vars.transform_keys(&:to_s).transform_values { |v| v.nil? ? '' : v.to_s }
      end

      def binding_for_erb
        binding
      end

      def v(key)
        @vars[key.to_s]
      end

      def ls(key)
        line = EnvFile.build_line(key, v(key))
        line ? "#{line}\n" : ''
      end

      def https_enabled?
        v('MAIN_DOMAIN_CERT_RESOLVER').to_s.strip != ''
      end

      # STORAGE_SAAS_DEFAULT_SERVICE：local / qinium / aliyun / amazon
      def saas_storage
        v('STORAGE_SAAS_DEFAULT_SERVICE').to_s.strip
      end

      def saas_storage_qinium?
        saas_storage == 'qinium'
      end

      def saas_storage_aliyun_oss?
        saas_storage == 'aliyun'
      end

      def saas_storage_amazon_s3?
        saas_storage == 'amazon'
      end

      def sentry_vars_present?
        v('SENTRY_DSN').to_s.strip != '' || v('SENTRY_CURRENT_ENV').to_s.strip != ''
      end

      def github_proxy_present?
        v('GITHUB_PROXY_URL').to_s.strip != ''
      end

      def storage_hint
        case saas_storage
        when 'local'
          '当前选型：local（需将项目 storage 挂载进容器）'
        when 'qinium'
          '当前选型：七牛云（仅输出下方 Qiniu 变量）'
        when 'aliyun'
          '当前选型：阿里云 OSS（仅输出下方 OSS 变量）'
        when 'amazon'
          '当前选型：AWS S3（仅输出下方 S3 变量）'
        else
          '当前选型：请与 STORAGE_SAAS_DEFAULT_SERVICE 对齐'
        end
      end
    end
  end
end
