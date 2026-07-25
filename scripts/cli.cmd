@echo off
setlocal EnableDelayedExpansion

REM 在项目根目录执行常用 docker compose 命令（与 scripts/cli.sh 一致）
REM 用法: scripts\cli.cmd <config|install|start|stop|restart|uninstall|clean|import-themes> [参数...]

cd /d "%~dp0.."

set "CLI_FILE=docker-compose.cli.yml"
if not defined COMPOSE_PROJECT_NAME (
  for %%I in ("%CD%") do set "COMPOSE_PROJECT_NAME=%%~nxI"
)

if "%~1"=="" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--help" goto usage

if /i "%~1"=="config" (
  docker compose -f "%CLI_FILE%" run --rm config %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="install" (
  set "HOST_PROJECT_ROOT=%CD%"
  docker compose -f "%CLI_FILE%" run --rm -e COMPOSE_PROJECT_NAME -e HOST_PROJECT_ROOT install %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="start" (
  if not exist docker-compose.yml (
    echo docker-compose.yml not found. Run: %~nx0 config
    exit /b 1
  )
  docker compose up -d %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="stop" (
  docker compose stop %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="restart" (
  docker compose restart %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="uninstall" (
  docker compose -f docker-compose.yml down --remove-orphans %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="clean" (
  docker compose -f "%CLI_FILE%" run --rm -e COMPOSE_PROJECT_NAME clean %2 %3 %4 %5 %6 %7 %8 %9
  exit /b %ERRORLEVEL%
)
if /i "%~1"=="import-themes" (
  set SKIP_CLONE=0
  set CLONE_ONLY=0
  if /i "%~2"=="--skip-clone" set SKIP_CLONE=1
  if /i "%~2"=="--clone-only" set CLONE_ONLY=1
  if /i "%~3"=="--skip-clone" set SKIP_CLONE=1
  if /i "%~3"=="--clone-only" set CLONE_ONLY=1
  docker compose -f "%CLI_FILE%" run --rm -e COMPOSE_PROJECT_NAME -e SKIP_CLONE -e CLONE_ONLY -e THEME_WIKI_REPO -e THEME_DIR_NAME -e BAKLIB_CLI_IMAGE import-themes
  exit /b %ERRORLEVEL%
)

echo Unknown subcommand: %~1
:usage
echo Usage: %~nx0 ^<config^|install^|start^|stop^|restart^|uninstall^|clean^|import-themes^>
exit /b 1
