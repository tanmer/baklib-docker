# frozen_string_literal: true

require 'open3'

require_relative '../logger'
require_relative '../project_root'
require_relative '../env_file'
require_relative '../docker_compose'
require_relative '../ui'

module Baklib
  module Commands
    module Lifecycle
      module_function

      def non_interactive?
        ENV['NON_INTERACTIVE_MODE'].to_s == 'true' || ENV['NON_INTERACTIVE'] == '1'
      end

      def start
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        puts '=========================================='
        puts '🚀 启动 Baklib Docker Compose 服务'
        puts '=========================================='
        puts

        unless File.file?(File.join(root, '.env'))
          Logger.error('.env 不存在，请先运行: docker compose -f docker-compose.cli.yml run --rm config')
          exit 1
        end

        DockerCompose.check_docker!

        running, = Open3.capture2(*(compose + %w[ps --status running -q]), chdir: root)
        if running.to_s.strip != ''
          puts '❌ 服务已在运行，无需重复启动。'
          puts '   如需重启请执行: docker compose restart'
          exit 1
        end

        Logger.info('启动服务...')
        unless system(*compose, 'up', '-d', chdir: root)
          Logger.error('启动服务失败，请检查日志: docker compose logs')
          exit 1
        end

        puts
        Logger.success('服务启动完成！')
        puts
        print_access_hints(root)
        puts
        puts '常用命令：'
        puts '  docker compose restart  - 重启服务'
        puts '  docker compose stop       - 停止服务'
        puts "  #{DockerCompose.compose_cmd} logs -f  - 查看日志"
        puts "  #{DockerCompose.compose_cmd} ps      - 查看状态"
        puts
      end

      def stop
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        puts '=========================================='
        puts '🛑 停止 Baklib Docker Compose 服务'
        puts '=========================================='
        puts

        DockerCompose.check_docker!

        ps_out, = Open3.capture2(*(compose + %w[ps]), chdir: root)
        unless ps_out.to_s.include?('Up')
          Logger.info('没有运行中的服务')
          exit 0
        end

        puts '当前运行的服务：'
        system(*(compose + %w[ps]), chdir: root)
        puts

        ui = Ui.new(non_interactive: non_interactive?)
        default_yes = non_interactive?
        unless ui.yes?('确认要停止所有服务吗？', default: default_yes)
          Logger.info('操作已取消')
          exit 0
        end

        Logger.info('停止服务...')
        unless system(*compose, 'stop', chdir: root)
          Logger.error('停止服务失败')
          exit 1
        end

        puts
        Logger.success('服务已停止')
        puts
        puts '服务状态：'
        system(*(compose + %w[ps]), chdir: root)
        puts
      end

      def restart
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        puts '=========================================='
        puts '🔄 重启 Baklib Docker Compose 服务'
        puts '=========================================='
        puts

        unless File.file?(File.join(root, '.env'))
          Logger.error('.env 不存在，请先运行: docker compose -f docker-compose.cli.yml run --rm config')
          exit 1
        end

        DockerCompose.check_docker!

        Logger.info('重启服务...')
        unless system(*compose, 'restart', chdir: root)
          Logger.error('重启服务失败，请检查日志: docker compose logs')
          exit 1
        end

        puts
        Logger.info('等待服务启动...')
        sleep 5

        puts
        puts '=========================================='
        puts '📊 服务状态'
        puts '=========================================='
        puts
        system(*(compose + %w[ps]), chdir: root)
        puts

        Logger.success('服务重启完成！')
        puts
      end

      def print_access_hints(root)
        domain = EnvFile.read_value('MAIN_DOMAIN')
        protocol = EnvFile.read_value('INGRESS_PROTOCOL').strip
        protocol = 'http' if protocol.empty?
        port = EnvFile.read_value('INGRESS_PORT').strip
        phone = EnvFile.read_value('ADMIN_PHONE').strip

        return if domain.empty?

        url = if !port.empty? && port != '80' && port != '443'
                "#{protocol}://#{domain}:#{port}"
              else
                "#{protocol}://#{domain}"
              end

        puts
        puts '✅ 服务已启动。请访问下方地址，使用管理员手机号登录：'
        puts "   #{url}"
        puts "   管理员手机号：#{phone}" unless phone.empty?
      end
    end
  end
end
