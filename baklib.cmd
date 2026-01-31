@echo off
setlocal enabledelayedexpansion

REM Baklib CLI (Windows): config | install | start | stop | restart | uninstall | clean | import-themes

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
        echo Services already running. Use %~nx0 restart to restart.
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
            echo Services started. Open: !START_PROTO!://!START_DOM!
            if not "!START_PHONE!"=="" echo Admin phone: !START_PHONE!
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
    echo Stopping and removing containers, keeping .env and volumes...
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    set "COMPOSE_PROJECT_NAME=!PROJ!"
    docker compose -f docker-compose.yml down --remove-orphans
    echo Done. Run %~nx0 install then %~nx0 start to start again. Use %~nx0 clean to remove all data.
    goto end
)
if "%~1"=="clean" (
    for %%I in ("%CD%") do set "PROJ=%%~nxI"
    docker compose -f "%CLI_FILE%" run --rm -e "COMPOSE_PROJECT_NAME=!PROJ!" clean
    goto end
)
if "%~1"=="import-themes" goto do_import_themes

echo Unknown subcommand: %~1
goto usage

:do_import_themes
shift
for %%I in ("%CD%") do set "PROJ=%%~nxI"
docker compose -f "%CLI_FILE%" run --rm -e "COMPOSE_PROJECT_NAME=!PROJ!" import-themes bash ./scripts/import-themes.sh %*
goto end

:usage
echo Usage: %~nx0 ^<subcommand^> [options...]
echo.
echo Subcommands:
echo   config         Generate/update .env (interactive)
echo   install        Login registry, pull images (run config first)
echo   start          Start stack
echo   stop           Stop stack
echo   restart        Restart stack
echo   uninstall      Remove containers, keep .env and volumes
echo   clean          Remove containers, networks and volumes (3 confirmations)
echo   import-themes  Import theme template (required once), options: --skip-clone, --clone-only
echo.
echo Examples:
echo   %~nx0 config
echo   %~nx0 install
echo   %~nx0 start
exit /b 1

:end
exit /b %ERRORLEVEL%
