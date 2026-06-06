#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/falcga/tb/main"
BIN_DIR="$HOME/.local/bin"
TARGET="$BIN_DIR/tb"

echo "📦 Installing Terminal Browser (tb)..."

if ! command -v curl &> /dev/null; then
    echo "curl not found. Please install curl and try again."
    exit 1
fi

mkdir -p "$BIN_DIR"

echo "Downloading tb..."
curl -sSL "${REPO_URL}/tb" -o "$TARGET"
chmod +x "$TARGET"

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    echo "✅ Added $BIN_DIR to PATH. Restart your terminal or run: source ~/.bashrc"
fi

echo "✅ Installed to $TARGET"
echo ""
echo "⚠️  Don't forget to set the JINA_TOKEN environment variable (optional):"
echo "   export JINA_TOKEN='your_token_here'"
echo ""
echo "Now you can use: tb https://example.com"