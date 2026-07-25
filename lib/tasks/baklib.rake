# frozen_string_literal: true

require_relative '../baklib/render_yaml'
require_relative '../baklib/commands/config'
require_relative '../baklib/commands/install'
require_relative '../baklib/commands/import_themes'
require_relative '../baklib/commands/clean'
require_relative '../baklib/commands/lifecycle'

def baklib_argv
  return BAKLIB_ARGV if defined?(BAKLIB_ARGV)

  ARGV.dup
end

desc '仅根据当前 .env 渲染 docker-compose.yml 与 traefik/etc/**/*.yml（不跑配置向导）'
task :render_yaml do
  Baklib::RenderYaml.render
end

desc '生成/更新 .env 并渲染 Traefik/Compose YAML（docker compose -f docker-compose.cli.yml run --rm config）'
task :config do
  Baklib::Commands::Config.run(argv: baklib_argv)
end

desc '准备：登录镜像仓库、拉取镜像（docker compose -f docker-compose.cli.yml run --rm install，需传 COMPOSE_PROJECT_NAME 等，见 docker-compose.cli.yml 注释）'
task :install do
  Baklib::Commands::Install.run
end

desc '导入主题模版到数据库（docker compose … run import-themes）；ENV: SKIP_CLONE=1, CLONE_ONLY=1, THEME_WIKI_REPO, THEME_DIR_NAME'
task :import_themes do
  Baklib::Commands::ImportThemes.run
end

desc '彻底清理容器、网络与数据卷（docker compose … run clean，需三次验证码）'
task :clean do
  Baklib::Commands::Clean.run
end

desc '启动主栈（docker compose up -d）'
task :start do
  Baklib::Commands::Lifecycle.start
end

desc '停止主栈（docker compose stop）'
task :stop do
  Baklib::Commands::Lifecycle.stop
end

desc '重启主栈（docker compose restart）'
task :restart do
  Baklib::Commands::Lifecycle.restart
end
