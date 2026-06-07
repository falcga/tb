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

# Copy the actual tb.sh file instead of embedding via heredoc
if curl -sSL --fail "https://raw.githubusercontent.com/falcga/tb/main/tb.sh" -o "$TARGET"; then
    echo "✅ tb.sh downloaded successfully"
else
    echo "❌ Error: Failed to download tb.sh from GitHub"
    exit 1
fi

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