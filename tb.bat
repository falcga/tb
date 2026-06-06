@echo off
setlocal enabledelayedexpansion


if "%JINA_TOKEN%"=="" (
    echo [Error] Environment variable JINA_TOKEN is not set.
    echo Set it with: set JINA_TOKEN=your_token
    exit /b 1
)

set "TOKEN=%JINA_TOKEN%"
set "CONTEXT=%JINA_CONTEXT_TOKEN%"
set "URL_OR_QUERY="
set "RAW_MODE=0"

:parse_args
if "%~1"=="" goto :check_query
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help
if "%~1"=="--raw" (
    set "RAW_MODE=1"
    shift
    goto :parse_args
)
if "%~1"=="--token" (
    set "TOKEN=%~2"
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

set "HEADERS=-H "Authorization: Bearer %TOKEN%" -H "X-Engine: browser""
if not "%CONTEXT%"=="" set "HEADERS=%HEADERS% -H "X-Context: %CONTEXT%""

if "%RAW_MODE%"=="1" (
    curl -sS %HEADERS% "%TARGET_URL%"
) else (
    curl -sS %HEADERS% "%TARGET_URL%" | more
)

if errorlevel 1 (
    echo [Error] Request failed.
    exit /b 1
)

exit /b 0

:help
echo Usage: tb.bat [--token TOKEN] [--context TOKEN] [--raw] ^<URL or query^>
echo.
echo   --token TOKEN       Jina API token
echo   --context TOKEN     Context token (X-Context header)
echo   --raw               Output without pager (more)
echo   --help, -h          Show this help
echo.
echo Environment variables:
echo   JINA_TOKEN          Required API token
echo   JINA_CONTEXT_TOKEN  Optional context token
echo.
echo Example:
echo   set JINA_TOKEN=jina_xxx
echo   tb.bat https://example.com
echo   tb.bat "how to install python"
exit /b 0
