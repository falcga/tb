#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/tb"

echo "📦 Installing Terminal Browser (tb)..."

if ! command -v curl &> /dev/null; then
    echo "❌ curl not found. Please install curl first."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

cat > "$TARGET" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

command -v curl &>/dev/null || { echo -e "${RED}Error: curl not installed${NC}" >&2; exit 1; }

TOKEN="${JINA_TOKEN:-}"
CONTEXT="${JINA_CONTEXT_TOKEN:-}"
URL=""
RAW=false

urlencode() {
    local string="$1"
    local encoded=""
    local i c
    for ((i=0; i<${#string}; i++)); do
        c="${string:i:1}"
        case "$c" in
            [a-zA-Z0-9._~-]) encoded+="$c" ;;
            ' ') encoded+="%20" ;;
            *) printf -v hex "%02X" "'$c"; encoded+="%$hex" ;;
        esac
    done
    printf "%s" "$encoded"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --token) TOKEN="$2"; shift 2 ;;
        --context) CONTEXT="$2"; shift 2 ;;
        --raw) RAW=true; shift ;;
        --help|-h) cat << HELP
Usage: tb [--token TOKEN] [--context TOKEN] [--raw] <URL or query>

Options:
  --token TOKEN       Jina API token (optional, also via JINA_TOKEN)
  --context TOKEN     Context token (X-Context header)
  --raw               Output without pager
  --help, -h          Show this help

Examples:
  tb https://example.com
  tb "bash tutorial"
  tb --token jina_xxx https://news.ycombinator.com
HELP
            exit 0
            ;;
        -*|--*) echo "Unknown option: $1" >&2; exit 1 ;;
        *) URL="$1"; shift ;;
    esac
done

[[ -z "$URL" ]] && { echo -e "${RED}Error: no URL or query provided${NC}" >&2; exit 1; }

if [[ "$URL" =~ ^https?:// ]]; then
    TARGET_URL="https://r.jina.ai/${URL}"
else
    ENC="$(urlencode "$URL")"
    TARGET_URL="https://s.jina.ai/${ENC}"
fi

HEADERS=(-H "X-Engine: browser")
[[ -n "$TOKEN" ]] && HEADERS+=(-H "Authorization: Bearer $TOKEN")
[[ -n "$CONTEXT" ]] && HEADERS+=(-H "X-Context: $CONTEXT")

echo -e "${GREEN}→ Fetching:${NC} $TARGET_URL" >&2

if [[ "$RAW" == true ]] || [[ ! -t 1 ]]; then
    curl -sS "${HEADERS[@]}" "$TARGET_URL"
else
    curl -sS "${HEADERS[@]}" "$TARGET_URL" | less -R
fi
EOF

chmod +x "$TARGET"

# Add ~/.local/bin to PATH if not already present
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    SHELL_CONFIG=""
    if [[ -f "$HOME/.bashrc" ]]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi
    if [[ -n "$SHELL_CONFIG" ]]; then
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_CONFIG"
        echo "✅ Added $INSTALL_DIR to PATH in $SHELL_CONFIG"
        echo "   Please restart your terminal or run: source $SHELL_CONFIG"
    else
        echo "⚠️  Could not find .bashrc or .zshrc. Add $INSTALL_DIR to PATH manually."
    fi
fi

echo "✅ Terminal Browser installed to $TARGET"
echo ""
echo " ⚠️ Don't forget to set JINA_TOKEN for higher rate limits:"
echo "   export JINA_TOKEN='your_token_here'"
echo ""
echo "🚀 Now you can use: tb https://example.com"