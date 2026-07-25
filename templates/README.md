# 配置模板（Generator 风格）

本目录存放 **ERB 源模板**，与 [Rails generators](https://guides.rubyonrails.org/generators.html) 类似：编辑此处文件。**生成物**（根目录 `docker-compose.yml`、`traefik/etc/**/*.yml` 等）由 `rake config` 写入工作区，**已加入仓库 `.gitignore`**，不随 `git clone` 下发；克隆后须先执行 `docker compose -f docker-compose.cli.yml run --rm config` 生成。

| 模板 | 生成到 |
|------|--------|
| `docker-compose.yml.erb` | `../docker-compose.yml` |
| `traefik/etc/traefik.yml.erb` | `../traefik/etc/traefik.yml` |
| `traefik/etc/dynamic/common.yml.erb` | `../traefik/etc/dynamic/common.yml` |
| `traefik/etc/dynamic/sni-strict.yml.erb` | `../traefik/etc/dynamic/sni-strict.yml`（TLS 版本由 `TRAEFIK_TLS_ENABLE_12` / `TRAEFIK_TLS_ENABLE_13` 控制） |
| `traefik/etc/dynamic/traefik-dashboard.yml.erb` | `../traefik/etc/dynamic/traefik-dashboard.yml` |
| `.env.erb` + `env_defaults.env` | `../.env`（`rake config` 合并向导结果与现有 `.env`）；变量说明见模板内注释与 `env_defaults.env` |

渲染逻辑：YAML 见 `lib/baklib/render_yaml.rb`；`.env` 见 `lib/baklib/render_env.rb`。交互 CLI 使用 **Thor::Shell**（`ask` / `say` 等）与 **tty-prompt**（列表多选），见 `lib/baklib/ui.rb`。
