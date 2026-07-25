# frozen_string_literal: true

require 'erb'
require 'fileutils'
require 'uri'
require 'dotenv'
require_relative 'project_root'
require_relative 'logger'

module Baklib
  module RenderYaml
    module_function

    # 源模板在 templates/ 下（类似 Rails generator），生成物仍在仓库根目录与 traefik/ 下
    TEMPLATES = [
      %w[traefik/etc/traefik.yml.erb traefik/etc/traefik.yml],
      %w[traefik/etc/dynamic/common.yml.erb traefik/etc/dynamic/common.yml],
      %w[traefik/etc/dynamic/sni-strict.yml.erb traefik/etc/dynamic/sni-strict.yml],
      %w[traefik/etc/dynamic/traefik-dashboard.yml.erb traefik/etc/dynamic/traefik-dashboard.yml],
      %w[docker-compose.yml.erb docker-compose.yml]
    ].freeze

    def template_path(root, rel_under_templates)
      File.join(root, 'templates', rel_under_templates)
    end

    def load_dotenv(path)
      return unless File.file?(path)

      ENV.update(Dotenv.parse(path))
    end

    def render(root = ProjectRoot.call)
      env_path = File.join(root, '.env')
      load_dotenv(env_path)

      TEMPLATES.each do |rel_tmpl, rel_out|
        erb_path = template_path(root, rel_tmpl)
        out_path = File.join(root, rel_out)

        unless File.file?(erb_path)
          warn "跳过（缺少模板）: templates/#{rel_tmpl}"
          next
        end

        ctx = RenderBinding.new
        erb = ERB.new(File.read(erb_path, encoding: 'UTF-8'), trim_mode: '-')
        FileUtils.mkdir_p(File.dirname(out_path))
        File.write(out_path, erb.result(ctx.instance_eval { binding }))
        Logger.info("已渲染 #{rel_out}")
      end
    end

    # ERB 绑定对象（模板中调用的辅助方法）
    class RenderBinding
      def https_enabled?
        ENV['MAIN_DOMAIN_CERT_RESOLVER'].to_s.strip != ''
      end

      def storage_local?
        ENV.fetch('STORAGE_SAAS_DEFAULT_SERVICE', 'local').strip == 'local'
      end

      def traefik_read_timeout
        storage_local? ? 1200 : 300
      end

      def max_request_body_bytes
        storage_local? ? 10_737_418_240 : 104_857_600
      end

      def etcd_password_present?
        ENV['ETCD_ROOT_PASSWORD'].to_s.strip != ''
      end

      def acme_email
        e = ENV['ACME_EMAIL'].to_s.strip
        e.empty? ? 'acme-your-email@example.com' : e
      end

      def main_domain
        ENV.fetch('MAIN_DOMAIN', 'your-domain.com').to_s.strip
      end

      def dashboard_host
        d = main_domain
        return 'traefik-777.your-domain.com' if d.empty?

        "traefik-777.#{d}"
      end

      def cert_resolver
        ENV.fetch('MAIN_DOMAIN_CERT_RESOLVER', 'http01').to_s.strip
      end

      def asset_cdn_host_for_comment
        h = ENV['ASSET_CDN_HOST'].to_s.strip
        return 'asset-cdn.example.com' if h.empty?

        URI.parse(h).host || 'asset-cdn.example.com'
      rescue URI::InvalidURIError
        'asset-cdn.example.com'
      end

      def traefik_entry_point
        https_enabled? ? 'https' : 'http'
      end

      # Traefik TLS 版本（与 TRAEFIK_TLS_ENABLE_12 / TRAEFIK_TLS_ENABLE_13 对应，默认均开启）
      def traefik_tls_enable_12?
        truthy_env('TRAEFIK_TLS_ENABLE_12', default: true)
      end

      def traefik_tls_enable_13?
        truthy_env('TRAEFIK_TLS_ENABLE_13', default: true)
      end

      def traefik_tls_min_version
        if traefik_tls_enable_13? && !traefik_tls_enable_12?
          'VersionTLS13'
        else
          'VersionTLS12'
        end
      end

      # 仅 TLS 1.2 时限制 maxVersion，避免协商到 1.3
      def traefik_tls_max_version_line
        return unless traefik_tls_enable_12? && !traefik_tls_enable_13?

        'maxVersion: VersionTLS12'
      end

      private

      def truthy_env(key, default:)
        v = ENV[key].to_s.strip.downcase
        return default if v.empty?

        %w[y yes 1 true on].include?(v)
      end
    end
  end
end
