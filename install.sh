#!/bin/bash

# Zsh Setup - One Command Installation Script
# This script installs and configures zsh with oh-my-zsh and all required plugins

set -e  # Exit on any error

echo "🚀 Starting Zsh Setup Installation..."
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}➜${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on a supported system
if ! command -v apt >/dev/null 2>&1; then
    print_error "This script is designed for Debian/Ubuntu systems with apt package manager."
    exit 1
fi

# Step 1: Install zsh if not already installed
print_step "Installing zsh..."
if command -v zsh >/dev/null 2>&1; then
    print_success "zsh is already installed"
else
    sudo apt update
    sudo apt install -y zsh
    print_success "zsh installed successfully"
fi

# Step 2: Install oh-my-zsh if not already installed
print_step "Installing oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    print_success "oh-my-zsh is already installed"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "oh-my-zsh installed successfully"
fi

# Step 3: Install powerlevel10k theme
print_step "Installing powerlevel10k theme..."
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    print_success "powerlevel10k is already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    print_success "powerlevel10k installed successfully"
fi

# Step 4: Install required plugins
print_step "Installing zsh plugins..."

# fzf-tab
if [ -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
    print_success "fzf-tab is already installed"
else
    git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
    print_success "fzf-tab installed"
fi

# zsh-autosuggestions
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_success "zsh-autosuggestions is already installed"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    print_success "zsh-autosuggestions installed"
fi

# zsh-syntax-highlighting
if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_success "zsh-syntax-highlighting is already installed"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    print_success "zsh-syntax-highlighting installed"
fi

# zsh-completions
if [ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    print_success "zsh-completions is already installed"
else
    git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
    print_success "zsh-completions installed"
fi

# Step 5: Install autojump
print_step "Installing autojump..."
if command -v autojump >/dev/null 2>&1; then
    print_success "autojump is already installed"
else
    sudo apt install -y autojump
    print_success "autojump installed successfully"
fi

# Step 6: Backup existing .zshrc and install new one
print_step "Setting up .zshrc configuration..."
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Existing .zshrc backed up"
fi

# Download .zshrc from the repository
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.zshrc" ]; then
    cp "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    print_success ".zshrc configuration applied"
else
    # If running from a direct download, fetch from GitHub
    curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/.zshrc -o "$HOME/.zshrc"
    print_success ".zshrc configuration downloaded and applied"
fi

# Step 7: Set zsh as default shell
print_step "Setting zsh as default shell..."
if [ "$SHELL" = "$(which zsh)" ]; then
    print_success "zsh is already the default shell"
else
    # Try to change shell, but don't hang if it requires a password
    if echo | timeout 5 chsh -s $(which zsh) >/dev/null 2>&1; then
        print_success "zsh set as default shell (will take effect on next login)"
    else
        print_warning "Could not set zsh as default shell automatically"
        print_warning "You can set it manually later with: chsh -s $(which zsh)"
        print_warning "Or simply run 'exec zsh' to start using zsh in this session"
    fi
fi

echo ""
echo "======================================"
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
echo "======================================"
echo ""
print_warning "Important next steps:"
echo "1. Run 'exec zsh' or restart your terminal to start using the new setup"
echo "2. On first run, powerlevel10k will prompt you to configure the theme"
echo "3. Follow the powerlevel10k configuration wizard to customize your prompt"
echo ""
print_step "To start using your new zsh setup right now, run:"
echo -e "${YELLOW}exec zsh${NC}"
echo ""