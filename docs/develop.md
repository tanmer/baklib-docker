# 开发文档

## 配置模板（`templates/**/*.yml.erb`）

`docker compose -f docker-compose.cli.yml run --rm config`（即容器内 `rake config`）在写入 `.env` 后会通过 **`lib/baklib/render_yaml.rb`** 从 **`templates/`** 生成（**生成路径已列入 `.gitignore`**，仅本地存在）：

- `traefik/etc/traefik.yml`
- `traefik/etc/dynamic/common.yml`
- `traefik/etc/dynamic/sni-strict.yml`（TLS 1.2/1.3 开关见 `.env` 中 `TRAEFIK_TLS_ENABLE_*`）
- `traefik/etc/dynamic/traefik-dashboard.yml`
- `docker-compose.yml`

目录约定见根目录 **`templates/README.md`**（对齐 Rails generator：源模板集中存放）。

**修改方式**：编辑 **`templates/`** 下对应 `*.yml.erb`（及 `lib/baklib/render_yaml.rb` 中 `RenderBinding` 的辅助方法）；本地在已有 `.env` 时可直接执行 **`rake render_yaml`** 预览生成物（需已安装 Ruby 与 `dotenv` 等），完整流程仍用 `docker compose -f docker-compose.cli.yml run --rm config` 或 `NON_INTERACTIVE_MODE=true rake config`。

## 常用命令封装（可选）

与 **`docker-compose.cli.yml`** 顶部注释等价：

- Linux / macOS：`./scripts/cli.sh config|install|start|stop|restart|uninstall|clean|import-themes`
- Windows：`scripts\cli.cmd` 同上

维护者本地调试 CLI 镜像仍用 **`./scripts/build-dev-cli`**、**`./scripts/run-dev-cli`**。

## Rake 与用户路径 CLI

仓库根目录 **`Rakefile`** 加载 **`lib/tasks/baklib.rake`**。列出任务：

```bash
rake -T
```

实现代码位于 **`lib/baklib/`**（如 `commands/config.rb`）。**无 Gemfile**；依赖在 **`Dockerfile.cli`** 中 `gem install`：`rake`、`tty-prompt`、`dotenv`、`thor`（版本固定）。`.env` 使用 **dotenv**；交互使用 **Thor::Shell::Color**（`ask`/`say` 等）与 **tty-prompt**（`select`/`multi_select`），见 **`lib/baklib/ui.rb`**。

## 发布 baklib-cli 镜像（维护者）

```bash
./scripts/push-cli-image registry.devops.tanmer.com/library/baklib-cli:latest
```

## 本地调试 CLI 镜像（维护者）

```bash
./scripts/build-dev-cli
./scripts/run-dev-cli
```

## 配置回归测试

```bash
./scripts/test-config
```

依赖本机 **Ruby** 及与 **`Dockerfile.cli`** 相同版本的 **`rake`**、**`tty-prompt`**、**`dotenv`**、**`thor`**；脚本内通过 `NON_INTERACTIVE_MODE=true rake config` 覆盖多种 `.env` 组合。
