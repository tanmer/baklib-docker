# frozen_string_literal: true

require 'json'

module Baklib
  # 交互式 rake config 的断点草稿（Ctrl+C 后可从上次进度恢复默认值）
  class ConfigDraft
    FILE = '.config.tmp'

    class << self
      def path(root)
        File.join(root, FILE)
      end

      def load(root)
        p = path(root)
        return {} unless File.file?(p)

        JSON.parse(File.read(p, encoding: 'UTF-8'))
      rescue JSON::ParserError, Errno::ENOENT
        {}
      end

      def save(root, hash)
        p = path(root)
        tmp = "#{p}.#{Process.pid}.#{rand(10_000)}.tmp"
        File.write(tmp, JSON.pretty_generate(hash))
        File.chmod(0o600, tmp)
        File.rename(tmp, p)
        File.chmod(0o600, p)
      end

      def clear(root)
        File.delete(path(root)) if File.file?(path(root))
      end
    end
  end
end
