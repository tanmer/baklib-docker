# frozen_string_literal: true

module Baklib
  module Logger
    module_function

    def info(msg) = puts("\e[0;34mℹ️  #{msg}\e[0m")
    def success(msg) = puts("\e[0;32m✅ #{msg}\e[0m")
    def warning(msg) = puts("\e[1;33m⚠️  #{msg}\e[0m")
    def error(msg) = puts("\e[0;31m❌ #{msg}\e[0m")
  end
end
