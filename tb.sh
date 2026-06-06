#!/usr/bin/env bash
# Terminal Browser using Jina Reader API
# MIT License

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Dependency check
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl not found. Please install curl.${NC}" >&2
    exit 1
fi

# Default values
TOKEN="${JINA_TOKEN:-}"
CONTEXT_TOKEN="${JINA_CONTEXT_TOKEN:-}"
URL_OR_QUERY=""
RAW_MODE=false

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
        --help|-h)
            cat << EOF
Usage: tb [--token TOKEN] [--context TOKEN] [--raw] <URL or search query>

Options:
  --token TOKEN       Jina API token (optional, can also be set via JINA_TOKEN)
  --context TOKEN     Context token (X-Context header, optional)
  --raw               Output without pager (less)
  --help, -h          Show this help

Examples:
  tb --token jina_xxx https://example.com
  tb "search phrase"
  tb --context myctx https://news.ycombinator.com

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

if [[ "$RAW_MODE" == true ]] || [[ ! -t 1 ]]; then
    curl -sS "${HEADERS[@]}" "$TARGET_URL"
else
    curl -sS "${HEADERS[@]}" "$TARGET_URL" | less -R
fi
