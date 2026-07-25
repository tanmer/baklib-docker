# frozen_string_literal: true

require 'open3'

require_relative '../logger'
require_relative '../project_root'
require_relative '../docker_compose'

module Baklib
  module Commands
    module Clean
      module_function

      def run
        root = ProjectRoot.call
        compose = DockerCompose.compose_cmd.split
        Dir.chdir(root)

        puts '=========================================='
        puts '⚠️  警告：此操作将删除所有容器、网络和数据卷！'
        puts '=========================================='
        puts
        puts '⚠️  此操作不可逆，请确保已备份重要数据！'
        puts
        puts '⚠️  为了安全，需要连续输入 3 次不同的验证码才能执行清理操作'
        puts

        unless verify_triple_code
          puts
          puts '操作已取消，未执行任何清理操作。'
          exit 1
        end

        puts
        Logger.success('验证通过！')
        puts
        puts '=========================================='
        puts '开始清理 Docker Compose 资源...'
        puts '=========================================='
        puts

        DockerCompose.check_docker!

        puts '当前运行的服务:'
        system(*(compose + %w[ps]), chdir: root) || puts('  无运行的服务')
        puts

        puts '当前数据卷:'
        system(*(compose + %w[volumes]), chdir: root) || puts('  无数据卷')
        puts

        puts '1. 停止所有服务...'
        system(*(compose + %w[stop]), out: File::NULL, err: File::NULL, chdir: root) || puts('  无需要停止的服务')
        puts

        puts '2. 删除所有容器...'
        system(*(compose + %w[rm -f]), out: File::NULL, err: File::NULL, chdir: root) || puts('  无需要删除的容器')
        puts

        puts '3. 删除所有资源（容器、网络、数据卷）...'
        system(*(compose + %w[down -v --remove-orphans]), out: File::NULL, err: File::NULL, chdir: root) || puts('  无需要删除的资源')
        puts

        puts '=========================================='
        puts '清理完成！验证结果：'
        puts '=========================================='
        puts

        puts '剩余容器:'
        ps_out, = Open3.capture2(*(compose + %w[ps]), chdir: root)
        if ps_out.to_s.include?('NAME') && ps_out.lines.size > 1
          puts ps_out
        else
          puts '  ✓ 无剩余容器'
        end
        puts

        puts '剩余数据卷:'
        vol_out, = Open3.capture2(*(compose + %w[volumes]), chdir: root)
        if vol_out.to_s.include?('VOLUME NAME') && vol_out.lines.size > 1
          puts vol_out
        else
          puts '  ✓ 无剩余数据卷'
        end
        puts

        puts '剩余网络:'
        net_out, = Open3.capture2('docker', 'network', 'ls', err: File::NULL)
        if net_out.to_s.match?(/baklib/)
          puts net_out.lines.select { |l| l.include?('baklib') }.join
        else
          puts '  ✓ 无剩余网络'
        end
        puts

        puts '=========================================='
        puts '清理完成！'
        puts '=========================================='
      end

      def verify_triple_code
        required = 3
        confirmed = 0
        while confirmed < required
          code = rand(9000) + 1000
          puts
          puts '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
          case confirmed
          when 0
            puts '⚠️  第一次确认：请输入验证码以确认清理操作'
            puts '⚠️  此操作将删除所有容器、网络和数据卷！'
          when 1
            puts '⚠️  ⚠️  第二次确认：请再次输入验证码'
            puts '⚠️  ⚠️  此操作将永久删除所有数据，无法恢复！'
          else
            puts '🚨 🚨 🚨 第三次确认：请最后一次输入验证码'
            puts '🚨 🚨 🚨 这是最后一次确认，输入正确后将立即执行清理操作！'
            puts '🚨 🚨 🚨 此操作将永久删除所有容器、网络和数据卷，无法恢复！'
          end
          puts '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
          puts "验证码: #{code}"
          puts '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
          print '请输入验证码: '
          $stdout.flush
          user_input = $stdin.gets&.chomp

          if user_input == code.to_s
            confirmed += 1
            remaining = required - confirmed
            if confirmed < required
              puts
              puts "✅ 验证码正确！还需要 #{remaining} 次确认"
              puts(confirmed == 1 ? '⚠️  请确保您真的想要执行此危险操作！' : '🚨 这是最后一次确认，请谨慎操作！')
            end
          else
            puts
            puts '❌ 验证码错误！'
            puts '⚠️  为了安全，已重置确认次数，需要重新开始确认流程'
            confirmed = 0
          end
        end
        true
      end
    end
  end
end
