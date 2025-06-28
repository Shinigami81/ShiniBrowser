#!/bin/bash

set -e

INSTALL_DIR="$HOME/.shinibrowser"
SCRIPT_NAME="shinibrowser"

echo "=== Shinibrowser Uninstallation ==="
echo ""
echo "🗑️  This will remove:"
echo "   • Shinibrowser script and configuration"
echo "   • Search history"
echo "   • PATH entries from shell profile"
echo "   • All files in $INSTALL_DIR"
echo ""
echo "✅ This will NOT remove:"
echo "   • Python packages (openai, duckduckgo-search, rich, etc.)"
echo "   • Python installation"
echo ""

# Ask for confirmation
echo -n "Are you sure you want to uninstall Shinibrowser? (y/N): "
read -r CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Uninstallation cancelled."
    exit 0
fi

echo ""
echo "🧹 Starting cleanup..."

# Remove installation directory
if [ -d "$INSTALL_DIR" ]; then
    echo "🗂️  Removing installation directory: $INSTALL_DIR"
    rm -rf "$INSTALL_DIR"
    echo "✅ Installation directory removed"
else
    echo "ℹ️  Installation directory not found (already removed?)"
fi

# Clean up shell profiles
cleanup_profile() {
    local profile_file="$1"
    local profile_name="$2"
    
    if [ -f "$profile_file" ]; then
        echo "🔧 Cleaning up $profile_name..."
        
        # Create a temporary file for the cleaned profile
        temp_file=$(mktemp)
        
        # Remove Shinibrowser-related lines
        grep -v "# Shinibrowser - added automatically" "$profile_file" | \
        grep -v "export PATH=\"$INSTALL_DIR:\$PATH\"" | \
        grep -v "alias shini-history=" > "$temp_file"
        
        # Replace original file with cleaned version
        mv "$temp_file" "$profile_file"
        
        echo "✅ $profile_name cleaned"
    else
        echo "ℹ️  $profile_name not found"
    fi
}

# Clean up common shell profile files
cleanup_profile "$HOME/.bashrc" ".bashrc"
cleanup_profile "$HOME/.zshrc" ".zshrc"
cleanup_profile "$HOME/.bash_profile" ".bash_profile"
cleanup_profile "$HOME/.profile" ".profile"

# Remove from PATH in current session (if running)
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo "🔄 Removing from current session PATH..."
    export PATH=$(echo "$PATH" | sed -e "s|:$INSTALL_DIR||g" -e "s|$INSTALL_DIR:||g")
    echo "✅ Removed from current PATH"
fi

# Check if shinibrowser command is still accessible
if command -v shinibrowser &> /dev/null; then
    echo "⚠️  Warning: 'shinibrowser' command is still accessible"
    echo "   This might be due to:"
    echo "   • Another installation in a different location"
    echo "   • Cached PATH in current shell session"
    echo "   • Manual PATH modifications not detected"
    echo ""
    echo "   To completely remove from current session, run:"
    echo "   hash -r"
    echo "   or restart your terminal"
else
    echo "✅ 'shinibrowser' command successfully removed"
fi

echo ""
echo "🎉 === Uninstallation Complete! ==="
echo ""
echo "📋 What was removed:"
echo "   ✅ Shinibrowser script and executable"
echo "   ✅ Configuration files (including API key)"
echo "   ✅ Search history"
echo "   ✅ PATH entries from shell profiles"
echo "   ✅ Shell aliases (shini-history)"
echo ""
echo "📋 Next steps:"
echo "   • Restart your terminal or run: source ~/.bashrc (or ~/.zshrc)"
echo "   • Run 'hash -r' to clear command cache"
echo ""
echo "💡 To reinstall later, just run the installation script again!"
echo ""
echo "🙏 Thanks for using Shinibrowser!"