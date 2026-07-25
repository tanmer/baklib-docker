# frozen_string_literal: true

require 'open3'
require 'shellwords'

require_relative '../logger'
require_relative '../project_root'
require_relative '../env_file'
require_relative '../docker_compose'

module Baklib
  module Commands
    module ImportThemes
      module_function

      def run
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        DockerCompose.check_docker!

        unless File.file?(File.join(root, '.env'))
          Logger.error('未找到 .env，请先运行 rake config 或 docker compose -f docker-compose.cli.yml run --rm config')
          exit 1
        end

        repo = (rv = ENV['THEME_WIKI_REPO'].to_s.strip).empty? ? 'https://gitee.com/baklib/theme-wiki.git' : rv
        dir_name = (dv = ENV['THEME_DIR_NAME'].to_s.strip).empty? ? 'theme-wiki' : dv
        import_dir = "/rails/theme_repositories/#{dir_name}"
        skip_clone = %w[1 true yes].include?(ENV['SKIP_CLONE'].to_s.downcase)
        clone_only = %w[1 true yes].include?(ENV['CLONE_ONLY'].to_s.downcase)

        cli_image = begin
          v = ENV['BAKLIB_CLI_IMAGE'].to_s.strip
          v = EnvFile.read_value('BAKLIB_CLI_IMAGE').strip if v.empty?
          v.empty? ? 'registry.devops.tanmer.com/library/baklib-cli:latest' : v
        end

        unless skip_clone
          theme_volume = theme_volume_name
          if theme_volume.nil? || theme_volume.empty?
            Logger.info('主题卷尚未创建，先启动一次 web 以创建卷...')
            system(*(compose + %w[run --rm --no-deps web true]), out: File::NULL, err: File::NULL, chdir: root)
            theme_volume = theme_volume_name
          end
          if theme_volume.nil? || theme_volume.empty?
            Logger.error('无法获取主题卷名称，请先执行 docker compose up -d 启动服务后再运行 import-themes')
            exit 1
          end

          Logger.info('将 theme-wiki 克隆到主题仓库卷...')
          inner = "(test -d #{Shellwords.escape(dir_name)} && (cd #{Shellwords.escape(dir_name)} && git pull --ff-only) " \
                  "|| git clone --depth 1 #{Shellwords.escape(repo)} #{Shellwords.escape(dir_name)})"
          ok = system(
            'docker', 'run', '--rm',
            '-v', "#{theme_volume}:/data",
            '-w', '/data',
            cli_image,
            'bash', '-c', inner
          )
          unless ok
            Logger.error("克隆主题仓库失败，请检查网络或仓库地址: #{repo}")
            exit 1
          end
          Logger.success("主题仓库已就绪: #{dir_name}")
        end

        return if clone_only

        out, = Open3.capture2(*(compose + %w[ps web --status running]), chdir: root)
        unless out.to_s.include?('web')
          Logger.error('Web 服务未运行，请先执行 docker compose up -d 启动服务')
          if ENV['COMPOSE_PROJECT_NAME'].to_s != ''
            puts "  当前项目名: COMPOSE_PROJECT_NAME=#{ENV['COMPOSE_PROJECT_NAME']}"
            puts '  请确保在与执行 start 时相同的目录下运行 import-themes。'
          end
          exit 1
        end

        Logger.info("正在将主题导入数据库: dir=#{import_dir}")
        unless system(*(compose + ['exec', '-T', 'web', 'bin/rails', 'themes:import', "dir=#{import_dir}"]), chdir: root)
          Logger.error('主题导入失败')
          exit 1
        end

        Logger.info('正在将主题设为已发布...')
        ok_pub = system(
          *(compose + ['exec', '-T', 'web', 'bin/rails', 'runner',
                        'Theme.first.update(published_at: Time.zone.now)']),
          chdir: root
        )
        if ok_pub
          Logger.success('主题已设为已发布')
        else
          Logger.warning('主题发布状态更新失败（可能需在应用内手动发布）')
        end

        Logger.success('主题已导入到数据库，可在应用中使用 Wiki 模板。')
      end

      def theme_volume_name
        out, = Open3.capture2('docker', 'volume', 'ls', '--format', '{{.Name}}')
        out.to_s.split("\n").find { |n| n.include?('baklib-theme-repositories') }
      end
    end
  end
end
