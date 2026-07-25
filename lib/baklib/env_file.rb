# frozen_string_literal: true

require 'dotenv'
require 'fileutils'
require_relative 'project_root'
require_relative 'logger'
require_relative 'docker_compose'

module Baklib
  module EnvFile
    module_function

    def read_value(key, env_path = File.join(ProjectRoot.call, '.env'))
      return '' unless File.file?(env_path)

      Dotenv.parse(env_path).fetch(key, '').to_s
    rescue Dotenv::FormatError => e
      Logger.warning("解析 .env 失败（键 #{key}）: #{e.message}")
      ''
    rescue StandardError => e
      Logger.warning("读取 .env 键 #{key} 失败: #{e.message}")
      ''
    end

    def build_line(key, value)
      v = value.to_s
      case key
      when 'REGISTRY_USERNAME', 'REGISTRY_PASSWORD'
        "#{key}='#{v.gsub("'", "'\\\\''")}'"
      else
        return nil if v.empty?

        v.match?(/[\s"$`]/) ? "#{key}=\"#{v.gsub('"', '\\"')}\"" : "#{key}=#{v}"
      end
    end

    def update(key, value, env_path = File.join(ProjectRoot.call, '.env'))
      File.write(env_path, '') unless File.exist?(env_path)

      lines = File.read(env_path, encoding: 'UTF-8').lines
      idx = lines.find_index { |l| l.start_with?("#{key}=") }
      registry = %w[REGISTRY_USERNAME REGISTRY_PASSWORD].include?(key)

      new_line = build_line(key, value)
      if idx
        if value.to_s.empty? && !registry
          lines.delete_at(idx)
        elsif new_line
          lines[idx] = "#{new_line}\n"
        end
      elsif new_line && (!value.to_s.empty? || registry)
        lines << "#{new_line}\n"
      end
      File.write(env_path, lines.join)
    end

    def delete_keys(keys, env_path = File.join(ProjectRoot.call, '.env'))
      return unless File.file?(env_path)

      lines = File.read(env_path, encoding: 'UTF-8').lines
      keys.each { |key| lines.reject! { |l| l.start_with?("#{key}=") } }
      File.write(env_path, lines.join)
    end

    def validate(env_path = File.join(ProjectRoot.call, '.env'))
      unless File.file?(env_path)
        Logger.error(".env 文件不存在: #{env_path}")
        return false
      end

      begin
        Dotenv.parse(env_path)
      rescue Dotenv::FormatError => e
        Logger.error("解析 .env 失败: #{e.message}")
        return false
      end

      errors = 0
      line_num = 0
      File.foreach(env_path, encoding: 'UTF-8') do |line|
        line_num += 1
        stripped = line.strip
        next if stripped.empty? || stripped.start_with?('#')

        if stripped.count('"').odd?
          Logger.error(".env 文件第 #{line_num} 行有未匹配的双引号:\n  #{line}")
          errors += 1
        end
      end

      if errors.positive?
        Logger.error(".env 文件发现 #{errors} 个语法错误，请修复后再继续")
        return false
      end

      DockerCompose.validate_env_with_compose(env_path)
    end
  end
end
