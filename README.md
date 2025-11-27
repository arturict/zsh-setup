# Ubuntu Installation Guide – Artur's Z-Shell Setup

> This how-to describes **exclusively** the installation of my personal Zsh workflow on **Ubuntu 22.04 LTS (or newer)**.
> Powerlevel10k Prompt, Oh My Zsh and all plugins for Laravel, Git, Docker, Node/React and Python will be set up.


---

## Installation Options

You have **two options** to install this setup:

### Option 1: Automated Installation
```bash
bash <(curl -s https://raw.githubusercontent.com/arturict/zsh-setup/main/install-zsh-setup.sh)
```

After installation run & and configure powerlevel10k:
```bash
exec zsh
```
### Option 2: Manual Installation **(Recommended)**
Follow the step-by-step guide below for better understanding and control over the installation process.

---

## Manual Installation Steps

## Step 0 – Prerequisites

```bash
sudo apt update
sudo apt install -y zsh git curl fzf autojump \
  build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev python3-pip \
  tmux bat ripgrep
```

| Tool          | Purpose                     |
| ------------- | --------------------------- |
| `zsh`         | modern shell                |
| `git`, `curl` | installer/clone             |
| `fzf`         | fuzzy search & fzf-tab      |
| `autojump`    | fast directory hopping      |
| `tmux`        | terminal multiplexer        |
| `bat`         | better cat with syntax highlighting |
| `ripgrep`     | faster grep alternative     |
| Build-Libs    | necessary for **pyenv**     |

---

## Step 1 – Set Zsh as Default Shell

```bash
chsh -s $(which zsh)
exec zsh   # or open new terminal
```

---

## Step 2 – Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## Step 3 – Get Powerlevel10k Theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

---

## Step 4 – Clone External Plugins

```bash
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/Aloxaf/fzf-tab                  $ZSH_CUSTOM/plugins/fzf-tab
git clone https://github.com/zsh-users/zsh-autosuggestions   $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                                                             $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions       $ZSH_CUSTOM/plugins/zsh-completions
```

---

## Step 5 – GitHub CLI, pyenv, bun & uv (optional but recommended)

```bash
sudo apt install gh
curl https://pyenv.run | bash
curl -fsSL https://bun.sh/install | bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Follow the pyenv instructions to add the necessary `eval` lines to your `.zshrc`.

| Tool   | Purpose                                    |
| ------ | ------------------------------------------ |
| `gh`   | GitHub CLI                                 |
| `pyenv`| Python version manager                     |
| `bun`  | Fast JavaScript runtime & package manager  |
| `uv`   | Fast Python package installer              |

---

## Step 6 – Apply `.zshrc` Configuration

Create/replace **`~/.zshrc`** with the following base snippet (abbreviated):

```zsh
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
```

> Complete aliases and config can be found in the [repository](https://github.com/arturict/zsh-setup).
---

## Step 7 – Configure Prompt & Test

```bash
p10k configure
exec zsh
```

If no error messages appear and the prompt looks nice, Artur's setup is ready to use ✅

---
Optional:
Locale herunterladen
```zsh
sudo locale-gen de_CH.UTF-8
sudo update-locale LANG=de_CH.UTF-8

```
---

### Quick Test

```bash
git checkout <Tab>        # should appear interactively via fzf
j src                     # switches via autojump to last "src" directory
art migrate               # Laravel alias works
```
