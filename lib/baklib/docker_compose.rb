# frozen_string_literal: true

require 'open3'
require_relative 'project_root'
require_relative 'logger'

module Baklib
  module DockerCompose
    module_function

    def compose_cmd
      _out, status = Open3.capture2e('docker', 'compose', 'version')
      status.success? ? 'docker compose' : 'docker-compose'
    end

    def check_docker!
      raise '未找到 docker 命令，请先安装 Docker' unless system('command -v docker >/dev/null 2>&1')

      return if system('docker info >/dev/null 2>&1')

      raise 'Docker 未运行，请先启动 Docker'
    end

    def validate_env_with_compose(env_path)
      root = ProjectRoot.call
      compose_file = File.join(root, 'docker-compose.yml')
      return true unless File.file?(compose_file)

      argv = compose_cmd.split + ['--env-file', env_path, 'config']
      _out, err, status = Open3.capture3(*argv, chdir: root)
      return true if status.success?

      msg = "#{err}#{_out}"
      if msg.match?(/\.env|unexpected|syntax|variable name|failed to read|line \d+/i)
        Logger.error("Docker Compose 解析 .env 时出错：\n#{msg.lines.first(5).join}")
        return false
      end
      true
    rescue StandardError => e
      Logger.warning("Compose 校验跳过: #{e.message}")
      true
    end

    def run_shell(cmd_string, chdir: ProjectRoot.call)
      system({ 'PATH' => ENV.fetch('PATH') }, 'sh', '-c', cmd_string, chdir: chdir)
    end
  end
end
