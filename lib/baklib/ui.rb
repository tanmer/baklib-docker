# frozen_string_literal: true

# 交互风格对齐 Rails generator / Thor：ask、say、mask 使用 Thor::Shell::Color；
# 单选（是/否）与列表多选用 tty-prompt（Thor 无等价 select/multi_select）。
require 'thor/shell/color'
# Thor::Shell::Basic#ask 依赖 Thor::LineEditor；仅 require shell/color 不会加载 line_editor
require 'thor/line_editor'
require 'tty-prompt'
require_relative 'env_file'

module Baklib
  class Ui
    attr_reader :non_interactive, :prompt, :shell

    def initialize(non_interactive: false)
      @non_interactive = non_interactive
      @shell = Thor::Shell::Color.new
      @prompt = TTY::Prompt.new
    end

    def ask(key, description, default: nil)
      d = default.nil? ? EnvFile.read_value(key) : default
      return d.to_s if non_interactive || !$stdin.tty?

      defl = d.empty? ? nil : d
      label = format_prompt_label(description)
      r = @shell.ask(label, nil, default: defl)
      r.nil? ? d.to_s : r.to_s
    end

    def mask(key, description, default: nil)
      d = default.nil? ? EnvFile.read_value(key) : default.to_s
      d = d.strip
      return d if non_interactive || !$stdin.tty?

      # 仅当确有已保存密码时提示「沿用」，避免无密码仍出现「回车保留」造成误解
      extra = d.empty? ? '' : '（已保存密码，直接回车可保持不变）'
      label = format_prompt_label("#{description}#{extra}")
      r = @shell.ask(label, nil, echo: false)
      r.to_s.empty? ? d : r.to_s
    end

    def yes?(message, default: false)
      return default if non_interactive || !$stdin.tty?

      idx = default ? 1 : 2
      @prompt.select(message, default: idx, cycle: true) do |menu|
        menu.choice('是', true)
        menu.choice('否', false)
      end
    end

    # choices: [[value, label], ...]
    # default: 与某一项的 value 一致时，高亮该项（否则 tty-prompt 始终默认第一项）
    def choose(message, choices, default: nil)
      val = default.nil? ? choices.first&.first : default
      return val if non_interactive || !$stdin.tty?

      idx = choices.find_index { |v, _| v.to_s == val.to_s }
      default_idx = idx.nil? ? 1 : idx + 1 # tty-prompt List 使用 1-based 索引

      @prompt.select(message, default: default_idx, cycle: true) do |menu|
        choices.each { |v, lbl| menu.choice(lbl, v) }
      end
    end

    def multi_select(message, choices, **opts)
      return Array(opts[:default]) if non_interactive || !$stdin.tty?

      @prompt.multi_select(message, choices, **opts)
    end

    # 向导式提问：说明文字后以全角冒号结尾，再接 Thor 的「(默认值)」与输入
    def format_prompt_label(description)
      s = description.to_s.rstrip
      return s if s.empty?
      return s if s.end_with?('：', ':', '？', '?', '！', '!')

      "#{s}："
    end
  end
end
