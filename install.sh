#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/falcga/tb/main"
BIN_PATH="/usr/local/bin/tb"
TMP_FILE="/tmp/tb.$$"

echo "📦 Installing Terminal Browser (tb)..."

# Check curl
if ! command -v curl &> /dev/null; then
    echo "curl not found. Please install curl and try again."
    exit 1
fi

echo "Downloading tb..."
curl -sSL "${REPO_URL}/tb" -o "$TMP_FILE"

sudo install -m 755 "$TMP_FILE" "$BIN_PATH"
rm -f "$TMP_FILE"

echo "✅ Installed to $BIN_PATH"
echo ""
echo "⚠️  Don't forget to set the JINA_TOKEN environment variable:"
echo "   export JINA_TOKEN='your_token_here'"
echo ""
echo "To make it permanent, add to ~/.bashrc or ~/.zshrc:"
echo "   echo 'export JINA_TOKEN=\"your_token_here\"' >> ~/.bashrc"
echo ""
echo "Now you can use: tb https://example.com"
