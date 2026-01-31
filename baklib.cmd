@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Baklib 统一入口（Windows）：通过 docker compose 执行 config / install / start / stop / restart / import-themes
REM 用法: baklib.cmd config | install | start | stop | restart | import-themes [--skip-clone|--clone-only|...]

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
cd /d "%SCRIPT_DIR%"
set "CLI_FILE=docker-compose.cli.yml"

if "%~1"=="" goto usage
if "%~1"=="-h" goto usage
if "%~1"=="--help" goto usage

if "%~1"=="config" (
    docker compose -f "%CLI_FILE%" run --rm config
    goto end
)
if "%~1"=="install" (
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    set "HOST_PROJECT_ROOT=%CD%"
    docker compose -f "%CLI_FILE%" run --rm -e "COMPOSE_PROJECT_NAME=!PROJ!" -e "HOST_PROJECT_ROOT=!HOST_PROJECT_ROOT!" install
    goto end
)
if "%~1"=="start" (
    for /f "delims=" %%i in ('docker compose ps --status running -q 2^>nul') do (
        echo 服务已在运行，无需重复启动。
        echo    如需重启请执行: %~nx0 restart
        exit /b 1
    )
    docker compose up -d
    if exist .env (
        for /f "usebackq tokens=2 delims==" %%a in (`findstr /b "MAIN_DOMAIN=" .env 2^>nul`) do set "START_DOM=%%a"
        for /f "usebackq tokens=2 delims==" %%b in (`findstr /b "INGRESS_PROTOCOL=" .env 2^>nul`) do set "START_PROTO=%%b"
        for /f "usebackq tokens=2 delims==" %%c in (`findstr /b "ADMIN_PHONE=" .env 2^>nul`) do set "START_PHONE=%%c"
        set "START_DOM=!START_DOM:"=!"
        set "START_PROTO=!START_PROTO:"=!"
        set "START_PHONE=!START_PHONE:"=!"
        if not "!START_PROTO!"=="" set "START_PROTO=!START_PROTO: =!"
        if "!START_PROTO!"=="" set "START_PROTO=http"
        if not "!START_DOM!"=="" (
            echo.
            echo 服务已启动。请访问下方地址，使用管理员手机号登录：
            echo    !START_PROTO!://!START_DOM!
            if not "!START_PHONE!"=="" echo    管理员手机号：!START_PHONE!
            echo.
        )
    )
    goto end
)
if "%~1"=="stop" (
    docker compose stop
    goto end
)
if "%~1"=="restart" (
    docker compose restart
    goto end
)
if "%~1"=="uninstall" (
    echo 正在停止并移除容器（保留 .env 与数据卷）...
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    set "COMPOSE_PROJECT_NAME=!PROJ!"
    docker compose -f docker-compose.yml down --remove-orphans
    echo 已卸载。.env 与数据卷已保留，可再次执行 install 与 start。
    echo    若要彻底删除所有数据，请使用: %~nx0 clean
    goto end
)
if "%~1"=="clean" (
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    docker compose -f "%CLI_FILE%" run --rm -e "COMPOSE_PROJECT_NAME=!PROJ!" clean
    goto end
)
if "%~1"=="import-themes" (
    shift
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    docker compose -f "%CLI_FILE%" run --rm -e "COMPOSE_PROJECT_NAME=!PROJ!" import-themes bash ./scripts/import-themes.sh %*
    goto end
)

echo 未知子命令: %~1
goto usage

:usage
echo 用法: %~nx0 ^<子命令^> [参数...]
echo.
echo 子命令:
echo   config         生成/更新 .env（交互式配置）
echo   install        准备：登录仓库、拉取镜像（需先 config）
echo   start          启动主栈
echo   stop           停止主栈
echo   restart        重启主栈
echo   uninstall      停止并移除容器（保留 .env 与数据卷，可再次 start）
echo   clean          彻底清理容器、网络与数据卷（需 3 次验证码确认）
echo   import-themes  导入主题模版（首次必选），可传 --skip-clone、--clone-only
echo.
echo 示例:
echo   %~nx0 config
echo   %~nx0 install
echo   %~nx0 start
echo   %~nx0 uninstall
exit /b 1

:end
exit /b %ERRORLEVEL%
