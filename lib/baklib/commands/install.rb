# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'shellwords'

require_relative '../logger'
require_relative '../project_root'
require_relative '../env_file'
require_relative '../docker_compose'
require_relative '../ui'

module Baklib
  module Commands
    module Install
      module_function

      def non_interactive?
        ENV['NON_INTERACTIVE_MODE'].to_s == 'true' || ENV['NON_INTERACTIVE'] == '1'
      end

      def run
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        puts '=========================================='
        puts '🚀 Baklib 安装（准备镜像）'
        puts '=========================================='
        puts

        Logger.info('检查环境...')
        DockerCompose.check_docker!
        unless system(*(compose + %w[version]), out: File::NULL, err: File::NULL) ||
               system('docker-compose', 'version', out: File::NULL, err: File::NULL)
          Logger.error('未找到 docker compose，请先安装 Docker Compose')
          exit 1
        end
        Logger.success('环境检查通过')
        puts

        unless File.file?(File.join(root, '.env'))
          Logger.error('未找到 .env，请先执行 rake config 或 docker compose -f docker-compose.cli.yml run --rm config')
          exit 1
        end

        out, = Open3.capture2(*(compose + %w[ps web --status running]), chdir: root)
        if out.to_s.include?('web')
          Logger.error('检测到主栈（web）已在运行，无法执行 install。')
          puts '请先 docker compose -f docker-compose.yml down --remove-orphans 或 docker compose down，再 install。'
          exit 1
        end

        Logger.info('检查 Docker 镜像仓库认证...')
        reg_server = 'registry.devops.tanmer.com'
        u = EnvFile.read_value('REGISTRY_USERNAME')
        p = EnvFile.read_value('REGISTRY_PASSWORD')
        ui = Ui.new(non_interactive: non_interactive?)

        if u != '' && p != ''
          Logger.info("正在登录 Docker 镜像仓库: #{reg_server}")
          ok = system(
            { 'PATH' => ENV.fetch('PATH') },
            'sh', '-c',
            "printf '%s' #{Shellwords.escape(p)} | docker login #{Shellwords.escape(reg_server)} " \
            "--username #{Shellwords.escape(u)} --password-stdin",
            chdir: root
          )
          unless ok
            Logger.error('Docker 镜像仓库登录失败')
            exit 1
          end
          Logger.success('Docker 镜像仓库登录成功')
        else
          Logger.warning('未配置 REGISTRY_USERNAME / REGISTRY_PASSWORD')
          if ui.non_interactive
            Logger.error('非交互模式下无法在未配置凭证时继续拉取')
            exit 1
          end
          unless ui.yes?('是否仍继续尝试拉取？', default: false)
            puts '已取消。请先运行 config 配置凭证后再执行 install。'
            exit 1
          end
        end
        puts

        Logger.info('拉取 Docker 镜像...')
        unless system(*compose, 'pull', chdir: root)
          Logger.error('镜像拉取失败')
          exit 1
        end
        Logger.success('镜像拉取完成')
        puts

        admin = EnvFile.read_value('ADMIN_PHONE').strip
        if admin.empty?
          finish_install
          return
        end

        pem = File.join(root, 'product.pem')
        unless File.file?(pem)
          FileUtils.touch(pem)
          Logger.warning('product.pem 不存在，已创建空文件；请向客服申请证书后替换该文件。')
        end

        Logger.info('已配置管理员手机号，临时启动 web 执行数据库初始化...')
        Logger.info('执行 bin/rails db:prepare...')
        unless system(*compose, 'run', '--rm', 'web', 'bin/rails', 'db:prepare', chdir: root)
          Logger.error('db:prepare 失败')
          system(*compose, 'down', out: File::NULL, err: File::NULL, chdir: root)
          exit 1
        end

        Logger.info('写入首个用户登录手机号...')
        runner = 'u=User.order(:id).first; exit(0) if !u || ENV["ADMIN_PHONE"].to_s.empty?; ' \
                 'u.update!(mobile_phone: ENV["ADMIN_PHONE"]) if u.respond_to?(:mobile_phone=); puts "OK"'
        out_r, = Open3.capture2(
          { 'PATH' => ENV.fetch('PATH') },
          *compose, 'run', '--rm', '-e', "ADMIN_PHONE=#{admin}",
          'web', 'bin/rails', 'runner', runner,
          chdir: root, err: File::NULL
        )
        if out_r.to_s.include?('OK')
          Logger.success("首个用户登录手机号已设置为: #{admin}")
        else
          Logger.warning('未能自动写入首个用户手机号（可能尚无用户记录）')
        end

        system(*compose, 'down', out: File::NULL, err: File::NULL, chdir: root)
        puts
        finish_install
      end

      def finish_install
        Logger.success('安装完成！')
        puts '接下来可运行 start 启动服务，首次部署后运行 import-themes 导入主题。'
        puts '  docker compose up -d'
        puts '  docker compose -f docker-compose.cli.yml run --rm import-themes'
        puts
      end
    end
  end
end
