#!/bin/bash

# Ubuntu Installation Script – Artur's Z-Shell Setup
# Run with: bash install-zsh-setup.sh

set -e  # Exit on any error

echo "🚀 Starting Artur's Z-Shell Setup Installation..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${BLUE}📦 Step $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 0: Prerequisites
print_step "0" "Installing Prerequisites"
sudo apt update
sudo apt install -y zsh git curl fzf autojump \
    build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev python3-pip gh \
    tmux bat ripgrep
print_success "Prerequisites installed"

# Step 1: Set Zsh as default shell
print_step "1" "Setting Zsh as Default Shell"
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s $(which zsh)
    print_success "Default shell changed to Zsh (will take effect after logout/login)"
else
    print_success "Zsh is already the default shell"
fi

# Step 2: Install Oh My Zsh
print_step "2" "Installing Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # Install Oh My Zsh without running zsh afterwards
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    print_success "Oh My Zsh installed"
else
    print_success "Oh My Zsh already installed"
fi

# Step 3: Install Powerlevel10k Theme
print_step "3" "Installing Powerlevel10k Theme"
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k"
    print_success "Powerlevel10k theme installed"
else
    print_success "Powerlevel10k theme already installed"
fi

# Step 4: Install External Plugins
print_step "4" "Installing External Plugins"

# fzf-tab
if [ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]; then
    git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
    print_success "fzf-tab plugin installed"
else
    print_success "fzf-tab plugin already installed"
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    print_success "zsh-autosuggestions plugin installed"
else
    print_success "zsh-autosuggestions plugin already installed"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    print_success "zsh-syntax-highlighting plugin installed"
else
    print_success "zsh-syntax-highlighting plugin already installed"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
    print_success "zsh-completions plugin installed"
else
    print_success "zsh-completions plugin already installed"
fi

# Step 5: Install pyenv (optional)
print_step "5" "Installing pyenv"
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
    print_success "pyenv installed"
else
    print_success "pyenv already installed"
fi

# Step 5b: Install bun
print_step "5b" "Installing bun"
if ! command -v bun &> /dev/null; then
    curl -fsSL https://bun.sh/install | bash
    print_success "bun installed"
else
    print_success "bun already installed"
fi

# Step 5c: Install uv (fast Python package installer)
print_step "5c" "Installing uv"
if ! command -v uv &> /dev/null; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    print_success "uv installed"
else
    print_success "uv already installed"
fi

# Step 6: Create .zshrc configuration
print_step "6" "Creating .zshrc Configuration"

# Backup existing .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backed up existing .zshrc"
fi

# Create new .zshrc
cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ~/.zshrc
# ------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
  # Speed & Dev-Stack
  gitfast              # Git aliases & ultra-fast completion
  docker laravel composer node yarn pyenv
  gh                   # GitHub CLI aliases & completion
  tmux                 # tmux aliases & completions

  # Comfort & Productivity
  fzf-tab              # interactive fuzzy tab completion
  zsh-autosuggestions zsh-syntax-highlighting
  history-substring-search alias-finder autojump
  zsh-completions command-not-found colored-man-pages
)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------------------------------------
# Keybindings for history-substring-search (↑ / ↓ search)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Initialize autojump (path may vary depending on distro)
[ -f /usr/share/autojump/autojump.zsh ] && source /usr/share/autojump/autojump.zsh

# ------------------------------------------------------------
# Custom Aliases
alias art='php artisan'
alias sail='./vendor/bin/sail'
alias ni='npm install'
alias nr='npm run'
alias nrd='npm run dev'
alias ns='npm start'
alias ys='yarn start'
alias d='docker'
alias dc='docker compose'
alias vimdiff='vim -d'

# bat (better cat) - use batcat on Ubuntu/Debian
if command -v batcat &> /dev/null; then
  alias bat='batcat'
  alias cat='batcat'
fi

# ripgrep shortcuts
alias rg='rg --smart-case'
alias rgi='rg --ignore-case'

# bun shortcuts
alias bi='bun install'
alias br='bun run'
alias brd='bun run dev'
alias bs='bun start'
alias bx='bunx'
alias ba='bun add'
alias bad='bun add -d'

# uv shortcuts (fast Python package manager)
alias uvi='uv pip install'
alias uvr='uv pip uninstall'
alias uvs='uv pip sync'
alias uvc='uv pip compile'
alias uvv='uv venv'
alias uvx='uvx'

# ------------------------------------------------------------
# Python via pyenv
export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv >/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# ------------------------------------------------------------
# FZF (if installed)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ------------------------------------------------------------
# Paths, Locale & Default Editor
export PATH="$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL" ] && export PATH="$BUN_INSTALL/bin:$PATH"

# uv (installed by astral installer)
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

export EDITOR="vim"
export LANG=de_CH.UTF-8
export LC_ALL=de_CH.UTF-8
EOF

print_success ".zshrc configuration created"

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo "=================================================="
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your terminal or run: exec zsh"
echo "2. Configure your Powerlevel10k prompt with: p10k configure"
echo ""
echo -e "${BLUE}Quick test commands:${NC}"
echo "• git checkout <Tab>  (should show fzf interface)"
echo "• j src              (autojump to last 'src' directory)"
echo "• art migrate        (Laravel alias)"
echo ""
echo -e "${YELLOW}Note:${NC} If this is your first time, the shell change will take effect after logout/login."

# Ask if user wants to configure p10k now
echo ""
read -p "Do you want to configure Powerlevel10k now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "7" "Configuring Powerlevel10k"
    export SHELL=$(which zsh)
    exec zsh -c "p10k configure"
else
    echo -e "${BLUE}You can configure Powerlevel10k later by running: p10k configure${NC}"
fi
