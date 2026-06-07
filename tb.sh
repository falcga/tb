#!/usr/bin/env bash
# Terminal Browser using Jina Reader API
# MIT License

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Cross-platform config directory
if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
    CONFIG_DIR="${XDG_CONFIG_HOME}/tb"
elif [[ -n "${APPDATA:-}" ]]; then
    # Windows (Git Bash, WSL with Windows env)
    CONFIG_DIR="${APPDATA}/tb"
else
    CONFIG_DIR="${HOME}/.config/tb"
fi

CONFIG_FILE="${CONFIG_DIR}/config"

# Dependency check
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl not found. Please install curl.${NC}" >&2
    exit 1
fi

# Load saved token from config file
load_saved_token() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE" 2>/dev/null || true
    fi
}

# Save token to config file
save_token() {
    local token="$1"
    mkdir -p "$CONFIG_DIR"
    # Only save if token doesn't already exist in config
    if [[ ! -f "$CONFIG_FILE" ]] || ! grep -q "^JINA_TOKEN=" "$CONFIG_FILE"; then
        echo "JINA_TOKEN=\"$token\"" > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        echo -e "${GREEN}✓ Token saved to ${CONFIG_FILE}${NC}" >&2
    fi
}

# Load saved token on startup
load_saved_token

# Default values (env vars take precedence over saved config)
TOKEN="${JINA_TOKEN:-${SAVED_JINA_TOKEN:-}}"
CONTEXT_TOKEN="${JINA_CONTEXT_TOKEN:-}"
URL_OR_QUERY=""
RAW_MODE=true
USE_PAGER=false
TOKEN_PROVIDED_VIA_FLAG=false

# URL encode function (without external tools)
urlencode() {
    local string="$1"
    local encoded=""
    local length="${#string}"
    local i c
    for (( i=0; i<length; i++ )); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9._~-]) encoded+="$c" ;;
            ' ') encoded+='%20' ;;
            *) printf -v hex '%02X' "'$c"; encoded+="%$hex" ;;
        esac
    done
    printf "%s" "$encoded"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --token)
            TOKEN="$2"
            TOKEN_PROVIDED_VIA_FLAG=true
            shift 2
            ;;
        --context)
            CONTEXT_TOKEN="$2"
            shift 2
            ;;
        --raw)
            RAW_MODE=true
            shift
            ;;
        --pager)
            USE_PAGER=true
            RAW_MODE=false
            shift
            ;;
        --help|-h)
            cat << EOF
Usage: tb [--token TOKEN] [--context TOKEN] [--raw|--pager] <URL or search query>

Options:
  --token TOKEN       Jina API token (optional, can also be set via JINA_TOKEN)
  --context TOKEN     Context token (X-Context header, optional)
  --raw               Output raw text (default)
  --pager             Output with pager (less)
  --help, -h          Show this help

Examples:
  tb https://example.com
  tb --token jina_xxx https://example.com
  tb "search phrase"
  tb --context myctx https://news.ycombinator.com
  tb --pager https://example.com

Environment variables:
  JINA_TOKEN          Optional API token
  JINA_CONTEXT_TOKEN  Optional context token
EOF
            exit 0
            ;;
        -*)
            echo -e "${RED}Unknown flag: $1${NC}" >&2
            exit 1
            ;;
        *)
            URL_OR_QUERY="$1"
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$URL_OR_QUERY" ]]; then
    echo -e "${RED}Error: No URL or search query provided.${NC}" >&2
    exit 1
fi

# Save token if provided via --token flag and not already saved
if [[ "$TOKEN_PROVIDED_VIA_FLAG" == true ]] && [[ -n "$TOKEN" ]]; then
    save_token "$TOKEN"
fi

# Build Jina API URL
if [[ "$URL_OR_QUERY" =~ ^https?:// ]]; then
    TARGET_URL="https://r.jina.ai/${URL_OR_QUERY}"
else
    ENCODED_QUERY="$(urlencode "$URL_OR_QUERY")"
    TARGET_URL="https://s.jina.ai/${ENCODED_QUERY}"
fi

# Build headers array
HEADERS=(-H "X-Engine: browser")
if [[ -n "$TOKEN" ]]; then
    HEADERS+=(-H "Authorization: Bearer $TOKEN")
fi
if [[ -n "$CONTEXT_TOKEN" ]]; then
    HEADERS+=(-H "X-Context: $CONTEXT_TOKEN")
fi

# Execute
echo -e "${GREEN}→ Fetching:${NC} $TARGET_URL" >&2

if [[ "$USE_PAGER" == true ]] && [[ -t 1 ]]; then
    curl -sS "${HEADERS[@]}" "$TARGET_URL" | less -R
else
    curl -sS "${HEADERS[@]}" "$TARGET_URL"
fi
