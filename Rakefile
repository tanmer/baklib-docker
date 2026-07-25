# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
# 在 Rake 改写 ARGV 之前保留（供 config 等任务解析 --non-interactive）
BAKLIB_ARGV = ARGV.dup

require 'rake'

load File.expand_path('lib/tasks/baklib.rake', __dir__)
