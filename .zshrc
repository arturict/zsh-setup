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
  # Speed- & Dev-Stack
  gitfast              # Git-Aliasse & ultraschnelle Completion
  docker laravel composer node yarn pyenv
  gh                   # GitHub-CLI Aliasse & Completion

  # Komfort & Produktivität
  fzf-tab              # interaktive Fuzzy-Tab-Completion
  zsh-autosuggestions zsh-syntax-highlighting
  history-substring-search alias-finder autojump
  zsh-completions command-not-found colored-man-pages
)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------------------------------------
# Keybindings für history-substring-search (↑ / ↓ durchsuchen)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# autojump initialisieren (Pfad kann je nach Distro variieren)
[ -f /usr/share/autojump/autojump.zsh ] && source /usr/share/autojump/autojump.zsh

# ------------------------------------------------------------
# Eigene Aliasse
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

# ------------------------------------------------------------
# Python via pyenv
export PYENV_ROOT="$HOME/.pyenv"
if command -v pyenv >/dev/null; then
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# ------------------------------------------------------------
# FZF (falls installiert)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ------------------------------------------------------------
# Pfade, Locale & Standard-Editor
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="vim"
export LANG=de_CH.UTF-8
export LC_ALL=de_CH.UTF-8
