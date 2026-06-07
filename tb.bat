@echo off
setlocal enabledelayedexpansion

REM Terminal Browser for Windows CMD

REM Cross-platform config directory
if not "%APPDATA%"=="" (
    set "CONFIG_DIR=%APPDATA%\tb"
) else (
    set "CONFIG_DIR=%USERPROFILE%\.config\tb"
)
set "CONFIG_FILE=%CONFIG_DIR%\config"

REM Load saved token from config file
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,* delims==" %%a in ('type "%CONFIG_FILE%"') do (
        if "%%a"=="JINA_TOKEN" set "SAVED_JINA_TOKEN=%%b"
    )
)

set "TOKEN=%JINA_TOKEN%"
if "%TOKEN%"=="" if not "%SAVED_JINA_TOKEN%"=="" set "TOKEN=%SAVED_JINA_TOKEN%"
set "CONTEXT=%JINA_CONTEXT_TOKEN%"
set "URL_OR_QUERY="
set "USE_PAGER=0"
set "TOKEN_PROVIDED_VIA_FLAG=0"

:parse_args
if "%~1"=="" goto :check_query
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--raw" (
    set "USE_PAGER=0"
    shift
    goto :parse_args
)
if "%~1"=="--pager" (
    set "USE_PAGER=1"
    shift
    goto :parse_args
)
if "%~1"=="--token" (
    set "TOKEN=%~2"
    set "TOKEN_PROVIDED_VIA_FLAG=1"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--context" (
    set "CONTEXT=%~2"
    shift
    shift
    goto :parse_args
)
set "URL_OR_QUERY=%~1"
shift
goto :parse_args

:check_query
if "%URL_OR_QUERY%"=="" (
    echo [Error] No URL or search query provided.
    exit /b 1
)

REM Save token if provided via --token flag and not already saved
if "%TOKEN_PROVIDED_VIA_FLAG%"=="1" if not "%TOKEN%"=="" (
    if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
    if not exist "%CONFIG_FILE%" (
        echo JINA_TOKEN=%TOKEN% > "%CONFIG_FILE%"
        echo [Info] Token saved to %CONFIG_FILE%
    ) else (
        REM Check if token already exists
        findstr /b "JINA_TOKEN=" "%CONFIG_FILE%" >nul
        if errorlevel 1 (
            echo JINA_TOKEN=%TOKEN% > "%CONFIG_FILE%"
            echo [Info] Token saved to %CONFIG_FILE%
        )
    )
)

REM Determine mode and escape spaces for URL
echo %URL_OR_QUERY% | findstr /i "^http:// ^https://" >nul
if errorlevel 1 (
    set "MODE=search"
    set "QUERY=%URL_OR_QUERY: =%%20%"
    set "TARGET_URL=https://s.jina.ai/!QUERY!"
) else (
    set "MODE=read"
    set "TARGET_URL=https://r.jina.ai/%URL_OR_QUERY%"
)

echo → Fetching: %TARGET_URL%

set "HEADERS=-H "X-Engine: browser""
if not "%TOKEN%"=="" set "HEADERS=%HEADERS% -H "Authorization: Bearer %TOKEN%""
if not "%CONTEXT%"=="" set "HEADERS=%HEADERS% -H "X-Context: %CONTEXT%""

if "%USE_PAGER%"=="1" (
    curl -sS %HEADERS% "%TARGET_URL%" | more
) else (
    curl -sS %HEADERS% "%TARGET_URL%"
)

if errorlevel 1 (
    echo [Error] Request failed.
    exit /b 1
)

exit /b 0

:help
echo Usage: tb.bat [--token TOKEN] [--context TOKEN] [--raw^|--pager] ^<URL or query^>
echo.
echo   --token TOKEN       Jina API token (optional)
echo   --context TOKEN     Context token (X-Context header, optional)
echo   --raw               Output raw text (default)
echo   --pager             Output with pager (more)
echo   --help, -h          Show this help
echo.
echo Environment variables:
echo   JINA_TOKEN          Optional API token
echo   JINA_CONTEXT_TOKEN  Optional context token
echo.
echo Example:
echo   set JINA_TOKEN=jina_xxx
echo   tb.bat https://example.com
echo   tb.bat "how to install python"
echo   tb.bat --pager https://example.com
exit /b 0
