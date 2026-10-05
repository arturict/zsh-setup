#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_NAME="$(basename "$0")"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
FZF_TAB_REPO="https://github.com/Aloxaf/fzf-tab.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
PYENV_REPO="https://github.com/pyenv/pyenv.git"
OH_MY_ZSH_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
BUN_INSTALL_URL="https://bun.com/install"
UV_INSTALL_URL="https://astral.sh/uv/install.sh"
NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
SOURCE_DIR="${DEVHUB_SOURCE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

APT_PACKAGES=(
  autojump
  bat
  build-essential
  ca-certificates
  command-not-found
  curl
  fzf
  gh
  git
  libbz2-dev
  libffi-dev
  libncursesw5-dev
  liblzma-dev
  libreadline-dev
  libsqlite3-dev
  libssl-dev
  libxml2-dev
  libxmlsec1-dev
  libzstd-dev
  make
  patch
  python3-pip
  python3-venv
  ripgrep
  tk-dev
  tmux
  unzip
  xz-utils
  zlib1g-dev
  zsh
)

NON_INTERACTIVE=0
FORCE_YES=0
SKIP_SHELL_CHANGE=0
SKIP_OPTIONAL_TOOLS=0
DOCTOR_ONLY=0

EXPECT_PYENV=1
EXPECT_BUN=1
EXPECT_UV=1
EXPECT_AI=1
EXPECT_DEVHUB=1

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Options:
  --yes, -y             Accept defaults and avoid prompts where possible.
  --non-interactive     Disable prompts entirely.
  --doctor              Verify the current setup without changing anything.
  --skip-shell-change   Do not run chsh.
  --skip-optional-tools Skip pyenv, bun, uv and AI CLIs.
  --help, -h            Show this help text.

Recommended:
  sudo bash $SCRIPT_NAME
EOF
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y)
      FORCE_YES=1
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
      FORCE_YES=1
      ;;
    --doctor)
      DOCTOR_ONLY=1
      ;;
    --skip-shell-change)
      SKIP_SHELL_CHANGE=1
      ;;
    --skip-optional-tools)
      SKIP_OPTIONAL_TOOLS=1
      EXPECT_PYENV=0
      EXPECT_BUN=0
      EXPECT_UV=0
      EXPECT_AI=0
      EXPECT_DEVHUB=0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run '$SCRIPT_NAME --help' for usage." >&2
      exit 1
      ;;
  esac
  shift
done

if [[ ! -t 0 || ! -t 1 ]]; then
  NON_INTERACTIVE=1
fi

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  BOLD=$'\033[1m'
  NC=$'\033[0m'
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  NC=""
fi

declare -a SUMMARY_INSTALLED=()
declare -a SUMMARY_UPDATED=()
declare -a SUMMARY_SKIPPED=()
declare -a SUMMARY_WARNINGS=()
declare -a SUMMARY_FAILURES=()

print_header() {
  echo
  echo -e "${BOLD}Artur's Zsh setup installer${NC}"
  echo "========================================"
}

print_step() {
  echo
  echo -e "${BLUE}[$1]${NC} $2"
}

print_success() {
  echo -e "${GREEN}[ok]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[warn]${NC} $1"
  SUMMARY_WARNINGS+=("$1")
}

print_error() {
  echo -e "${RED}[err]${NC} $1" >&2
}

on_error() {
  local line_no="$1"
  print_error "Installer stopped at line $line_no."
}

trap 'on_error "$LINENO"' ERR

is_root() {
  [[ "$(id -u)" -eq 0 ]]
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    print_error "Required command '$1' is missing."
    exit 1
  fi
}

verify_check() {
  local label="$1"
  local command_string="$2"

  if eval "$command_string"; then
    print_success "$label"
    return 0
  fi

  print_error "$label"
  SUMMARY_FAILURES+=("$label")
  return 1
}

target_user_from_env() {
  if is_root; then
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
      printf '%s\n' "$SUDO_USER"
      return
    fi

    if [[ -n "${TARGET_USER:-}" && "${TARGET_USER}" != "root" ]]; then
      printf '%s\n' "$TARGET_USER"
      return
    fi

    print_error "Run the script with sudo from the target account, or set TARGET_USER=<name>."
    exit 1
  fi

  printf '%s\n' "${USER}"
}

require_cmd getent

TARGET_USER="$(target_user_from_env)"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [[ -z "$TARGET_HOME" || ! -d "$TARGET_HOME" ]]; then
  print_error "Could not determine home directory for user '$TARGET_USER'."
  exit 1
fi

TARGET_ZSH="$TARGET_HOME/.oh-my-zsh"
TARGET_ZSH_CUSTOM="$TARGET_ZSH/custom"
TARGET_CONFIG_DIR="$TARGET_HOME/.config/artur-zsh-setup"
TARGET_CONFIG_FILE="$TARGET_CONFIG_DIR/zshrc.zsh"
TARGET_PROFILE_FILE="$TARGET_CONFIG_DIR/zprofile.zsh"
TARGET_ENV_FILE="$TARGET_CONFIG_DIR/env.zsh"
TARGET_ZSHENV_FILE="$TARGET_CONFIG_DIR/zshenv.zsh"
TARGET_COMPLETIONS_DIR="$TARGET_CONFIG_DIR/completions"
TARGET_ZSHRC="$TARGET_HOME/.zshrc"
TARGET_ZPROFILE="$TARGET_HOME/.zprofile"
TARGET_ZSHENV="$TARGET_HOME/.zshenv"
TARGET_BASHRC="$TARGET_HOME/.bashrc"
TARGET_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
ZSH_BIN="${ZSH_BIN:-/usr/bin/zsh}"

run_as_target_user() {
  local command_string="$1"

  if is_root; then
    if command -v sudo >/dev/null 2>&1; then
      sudo -H -u "$TARGET_USER" env HOME="$TARGET_HOME" USER="$TARGET_USER" bash -lc "$command_string"
      return
    fi

    if command -v runuser >/dev/null 2>&1; then
      runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" USER="$TARGET_USER" bash -lc "$command_string"
      return
    fi

    print_error "Need either 'sudo' or 'runuser' to switch to $TARGET_USER from root."
    return 1
  else
    env HOME="$TARGET_HOME" USER="$TARGET_USER" bash -lc "$command_string"
  fi
}

run_with_sudo() {
  if is_root; then
    "$@"
  else
    sudo "$@"
  fi
}

record_status() {
  local bucket="$1"
  local label="$2"

  case "$bucket" in
    installed)
      SUMMARY_INSTALLED+=("$label")
      ;;
    updated)
      SUMMARY_UPDATED+=("$label")
      ;;
    skipped)
      SUMMARY_SKIPPED+=("$label")
      ;;
  esac
}

prompt_yes_no() {
  local prompt="$1"
  local default_answer="$2"
  local reply=""

  if [[ "$FORCE_YES" -eq 1 ]]; then
    [[ "$default_answer" == "y" ]] && return 0
    return 1
  fi

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    [[ "$default_answer" == "y" ]] && return 0
    return 1
  fi

  if [[ "$default_answer" == "y" ]]; then
    read -r -p "$prompt [Y/n]: " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
    return
  fi

  read -r -p "$prompt [y/N]: " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_directory() {
  local dir_path="$1"
  run_as_target_user "mkdir -p '$dir_path'"
}

resolve_zsh_bin() {
  if command -v zsh >/dev/null 2>&1; then
    ZSH_BIN="$(command -v zsh)"
  fi

  if [[ ! -x "$ZSH_BIN" ]]; then
    print_error "zsh is not installed at '$ZSH_BIN'."
    exit 1
  fi
}

git_sync_repo() {
  local label="$1"
  local repo_url="$2"
  local destination="$3"

  if run_as_target_user "[[ -d '$destination/.git' ]]"; then
    if run_as_target_user "git -C '$destination' pull --ff-only"; then
      print_success "$label updated"
      record_status updated "$label"
    else
      print_warning "$label exists but could not fast-forward. Left untouched."
      record_status skipped "$label"
    fi
    return
  fi

  if run_as_target_user "[[ -e '$destination' ]]"; then
    print_warning "$label destination exists but is not a git checkout: $destination"
    record_status skipped "$label"
    return
  fi

  ensure_directory "$(dirname "$destination")"
  run_as_target_user "git clone --depth=1 '$repo_url' '$destination'"
  print_success "$label installed"
  record_status installed "$label"
}

install_oh_my_zsh() {
  if run_as_target_user "[[ -d '$TARGET_ZSH/.git' ]]"; then
    if run_as_target_user "git -C '$TARGET_ZSH' pull --ff-only"; then
      print_success "Oh My Zsh updated"
      record_status updated "Oh My Zsh"
    else
      print_warning "Oh My Zsh exists but could not fast-forward. Left untouched."
      record_status skipped "Oh My Zsh"
    fi
    return
  fi

  if run_as_target_user "[[ -d '$TARGET_ZSH' ]]"; then
    print_warning "Oh My Zsh directory exists but is not a git checkout: $TARGET_ZSH"
    record_status skipped "Oh My Zsh"
    return
  fi

  # Without an existing ~/.zshrc the Oh My Zsh installer writes its template,
  # which loads Oh My Zsh a second time below the managed block. An empty file
  # makes KEEP_ZSHRC apply; the managed loader block is added later.
  run_as_target_user "touch '$TARGET_ZSHRC'"
  run_as_target_user "RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \"\$(curl -fsSL '$OH_MY_ZSH_INSTALL_URL')\" \"\" --unattended"
  print_success "Oh My Zsh installed"
  record_status installed "Oh My Zsh"
}

install_or_update_bun() {
  local bun_bin="$TARGET_HOME/.bun/bin/bun"
  local existing_bun=""

  existing_bun="$(run_as_target_user "command -v bun 2>/dev/null || true")"

  if run_as_target_user "[[ -x '$bun_bin' ]]"; then
    run_as_target_user "'$bun_bin' upgrade"
    print_success "bun updated"
    record_status updated "bun"
    return
  fi

  if [[ -n "$existing_bun" && "$existing_bun" != "$bun_bin" ]]; then
    print_warning "bun already exists at $existing_bun. Installing a managed copy in $bun_bin."
  fi

  run_as_target_user "export SHELL='$ZSH_BIN'; curl -fsSL '$BUN_INSTALL_URL' | bash"
  print_success "bun installed"
  record_status installed "bun"
}

install_or_update_uv() {
  local uv_bin="$TARGET_HOME/.local/bin/uv"
  local existing_uv=""

  existing_uv="$(run_as_target_user "command -v uv 2>/dev/null || true")"

  if run_as_target_user "[[ -x '$uv_bin' ]]"; then
    run_as_target_user "UV_NO_MODIFY_PATH=1 '$uv_bin' self update"
    print_success "uv updated"
    record_status updated "uv"
    return
  fi

  if [[ -n "$existing_uv" && "$existing_uv" != "$uv_bin" ]]; then
    print_warning "uv already exists at $existing_uv. Installing a managed copy in $uv_bin."
  fi

  run_as_target_user "curl -LsSf '$UV_INSTALL_URL' | env UV_NO_MODIFY_PATH=1 sh"
  print_success "uv installed"
  record_status installed "uv"
}

maybe_optimize_pyenv() {
  if ! run_as_target_user "[[ -x '$TARGET_HOME/.pyenv/src/configure' ]]"; then
    return
  fi

  if run_as_target_user "cd '$TARGET_HOME/.pyenv' && src/configure && make -C src"; then
    print_success "pyenv native extension built"
  else
    print_warning "pyenv native extension build failed. Pyenv still works, just a bit slower."
  fi
}

install_or_update_pyenv() {
  git_sync_repo "pyenv" "$PYENV_REPO" "$TARGET_HOME/.pyenv"
  maybe_optimize_pyenv
}

refresh_generated_assets() {
  ensure_directory "$TARGET_COMPLETIONS_DIR"

  # The completions directory is on fpath, so _uv and _uvx are autoloaded on the
  # first <Tab> instead of parsing 7000 lines on every shell start. Older
  # releases sourced uv.zsh and uvx.zsh directly.
  run_as_target_user "rm -f '$TARGET_COMPLETIONS_DIR/uv.zsh' '$TARGET_COMPLETIONS_DIR/uvx.zsh'"

  if run_as_target_user "[[ -x '$TARGET_HOME/.local/bin/uv' ]]"; then
    if run_as_target_user "'$TARGET_HOME/.local/bin/uv' generate-shell-completion zsh > '$TARGET_COMPLETIONS_DIR/_uv'"; then
      print_success "uv completion refreshed"
    else
      print_warning "Could not generate uv completion"
    fi

    if run_as_target_user "'$TARGET_HOME/.local/bin/uvx' --generate-shell-completion zsh > '$TARGET_COMPLETIONS_DIR/_uvx'"; then
      print_success "uvx completion refreshed"
    else
      print_warning "Could not generate uvx completion"
    fi
  fi
}

write_managed_config() {
  local tmp_file
  tmp_file="$(mktemp)"

  cat <<'EOF' >"$tmp_file"
# Managed by Artur's zsh-setup installer.
# This file is sourced from ~/.zshrc and can be regenerated safely.
#
# Every terminal, tmux pane and `exec zsh` runs this file. Keep it free of
# subprocesses: tools are put on PATH directly, and slow initialisation (nvm,
# pyenv, completion scripts) is cached or deferred until first use.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[[ -r "$HOME/.config/artur-zsh-setup/env.zsh" ]] && source "$HOME/.config/artur-zsh-setup/env.zsh"

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"

if [[ ! -d "${XDG_CACHE_HOME:-$HOME/.cache}" || ! -d "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" ]]; then
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}" "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" 2>/dev/null
fi

# Generated completions such as _uv and _uvx are autoloaded on first use.
typeset -gU fpath
fpath=("$HOME/.config/artur-zsh-setup/completions" $fpath)

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000

typeset -ga plugins
plugins=(git gitfast colored-man-pages)

add_plugin_if_present() {
  local plugin="$1"

  if [[ -d "$ZSH/plugins/$plugin" || -d "$ZSH_CUSTOM/plugins/$plugin" ]]; then
    plugins+=("$plugin")
  fi
}

add_plugin_if_command() {
  local command_name="$1"
  local plugin="$2"

  if command -v "$command_name" >/dev/null 2>&1; then
    add_plugin_if_present "$plugin"
  fi
}

add_plugin_if_present "fzf-tab"
# zsh-completions only ships completion functions. They must be on fpath before
# Oh My Zsh runs compinit; loading it as a plugin adds them too late.
if [[ -d "$ZSH_CUSTOM/plugins/zsh-completions/src" ]]; then
  fpath+=("$ZSH_CUSTOM/plugins/zsh-completions/src")
fi
add_plugin_if_present "zsh-autosuggestions"
add_plugin_if_present "history-substring-search"
add_plugin_if_present "alias-finder"
add_plugin_if_present "laravel"
add_plugin_if_command "command-not-found" "command-not-found"
add_plugin_if_command "gh" "gh"
add_plugin_if_command "docker" "docker"
add_plugin_if_command "node" "node"
add_plugin_if_command "yarn" "yarn"
add_plugin_if_command "composer" "composer"
add_plugin_if_command "tmux" "tmux"

if command -v autojump >/dev/null 2>&1 || [[ -r /usr/share/autojump/autojump.zsh ]]; then
  add_plugin_if_present "autojump"
fi

# Keep syntax highlighting at the end so it can wrap prior completions cleanly.
add_plugin_if_present "zsh-syntax-highlighting"

ZSH_THEME="powerlevel10k/powerlevel10k"
source "$ZSH/oh-my-zsh.sh"

if [[ -r "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
fi

bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true

# The autojump plugin already sources this file; only load it when the plugin is absent.
if (( ! ${plugins[(Ie)autojump]} )) && [[ -r /usr/share/autojump/autojump.zsh ]]; then
  source /usr/share/autojump/autojump.zsh
fi

if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [[ -r /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'no matches for: %d'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':fzf-tab:*' switch-group ',' '.'

if command -v batcat >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [[ -d $realpath ]]; then ls --color=always $realpath; elif [[ -f $realpath ]]; then batcat --style=numbers --color=always $realpath; fi'
elif command -v bat >/dev/null 2>&1; then
  zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [[ -d $realpath ]]; then ls --color=always $realpath; elif [[ -f $realpath ]]; then bat --style=numbers --color=always $realpath; fi'
else
  zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -d $realpath ]] && ls --color=always $realpath'
fi

setopt AUTO_CD
setopt APPEND_HISTORY
setopt COMPLETE_IN_WORD
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP
setopt SHARE_HISTORY

take() {
  mkdir -p -- "$1" && cd -- "$1"
}

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
alias rg='rg --smart-case'
alias rgi='rg --ignore-case'
alias bi='bun install'
alias br='bun run'
alias brd='bun run dev'
alias bs='bun start'
alias bx='bunx'
alias ba='bun add'
alias bad='bun add --dev'
alias uvi='uv pip install'
alias uvr='uv pip uninstall'
alias uvs='uv pip sync'
alias uvc='uv pip compile'
alias uvv='uv venv'
alias uvx='uvx'
alias reload='exec zsh'

if command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
fi

if (( $+commands[pyenv] )); then
  # `pyenv init -` forks bash and rehashes on every start. Its output only
  # changes with pyenv itself or its plugins (it lists their `sh-` commands),
  # so cache it and rehash when an installed Python gained or lost executables
  # since the shims were last written.
  () {
    local init_cache="${XDG_CACHE_HOME:-$HOME/.cache}/artur-zsh-setup/pyenv-init.zsh"
    if [[ ! -s $init_cache || $PYENV_ROOT/libexec/pyenv-init -nt $init_cache ||
          $PYENV_ROOT/plugins -nt $init_cache ]]; then
      mkdir -p "${init_cache:h}"
      command pyenv init - --no-push-path --no-rehash zsh >|"$init_cache.$$" &&
        mv -f "$init_cache.$$" "$init_cache"
    fi
    [[ -s $init_cache ]] && source "$init_cache"

    local -a newest_bin=("$PYENV_ROOT"/versions/*/bin(N/om[1]))
    if (( $#newest_bin )) && [[ $newest_bin[1] -nt $PYENV_ROOT/shims ]]; then
      command pyenv rehash &>/dev/null &!
    fi
  }
fi

export EDITOR="${EDITOR:-vim}"
EOF

  install_managed_file "$tmp_file" "$TARGET_CONFIG_FILE"
  print_success "Managed zsh config written to $TARGET_CONFIG_FILE"
}

install_managed_file() {
  local tmp_file="$1"
  local destination="$2"

  ensure_directory "$TARGET_CONFIG_DIR"

  if is_root; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$tmp_file" "$destination"
  else
    install -m 0644 "$tmp_file" "$destination"
  fi

  rm -f "$tmp_file"
}

write_managed_env() {
  local tmp_file
  tmp_file="$(mktemp)"

  cat <<'EOF' >"$tmp_file"
# Managed by Artur's zsh-setup installer.
# PATH setup shared by zprofile.zsh and zshrc.zsh; can be regenerated safely.
#
# This runs for every login and interactive shell, so it must not fork.
# Sourcing nvm.sh used to cost more than the rest of the startup together:
# the default Node.js is now resolved from nvm's alias files, and nvm.sh is
# loaded the first time `nvm` itself is called.

typeset -gU path

export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export BUN_INSTALL="$HOME/.bun"

path=("$HOME/.local/bin" $path)
[[ -d "$PYENV_ROOT/bin" ]] && path=("$PYENV_ROOT/bin" $path)

# nvm_ls_current only exists once the real nvm.sh is loaded.
if [[ -s "$NVM_DIR/nvm.sh" ]] && (( ! $+functions[nvm_ls_current] )); then
  () {
    setopt local_options extended_glob

    # A parent shell already selected a version (`nvm use 18`, then `exec zsh`
    # or a new tmux pane): keep it, as loading nvm.sh would.
    if [[ -n ${NVM_BIN-} && $NVM_BIN == "$NVM_DIR"/versions/node/v*/bin && -d $NVM_BIN ]] &&
       (( ${path[(Ie)$NVM_BIN]} )); then
      :
    else
      # Follow default -> lts/* -> lts/<codename> -> vX.Y.Z like `nvm use default`.
      local target=default
      local -i hops
      for (( hops = 0; hops < 8; hops++ )); do
        [[ -r "$NVM_DIR/alias/$target" ]] || break
        target="$(<"$NVM_DIR/alias/$target")"
        target="${target//[[:space:]]/}"
      done

      local -a candidates
      case $target in
        (node|stable)
          candidates=("$NVM_DIR"/versions/node/v*(N/nOn)) ;;
        (v#<->(.<->)#)
          candidates=("$NVM_DIR/versions/node/v${target#v}"(N/) "$NVM_DIR/versions/node/v${target#v}".*(N/nOn)) ;;
      esac

      if (( ! $#candidates )); then
        # Aliases such as "system" or an uninstalled version: let nvm decide.
        source "$NVM_DIR/nvm.sh"
        return
      fi
      export NVM_BIN="$candidates[1]/bin" NVM_INC="$candidates[1]/include/node"
      path=("$NVM_BIN" $path)
    fi

    _artur_load_nvm() {
      unfunction nvm nvm_find_nvmrc
      source "$NVM_DIR/nvm.sh" --no-use
    }
    nvm() { _artur_load_nvm && nvm "$@" }
    # nvm's README snippet for switching on .nvmrc calls this helper directly.
    nvm_find_nvmrc() { _artur_load_nvm && nvm_find_nvmrc "$@" }
  }
fi

# Keep Bun after nvm so the managed Bun OpenCode binary wins over stale npm shims.
[[ -d "$BUN_INSTALL/bin" ]] && path=("$BUN_INSTALL/bin" $path)
[[ -d "$PYENV_ROOT/shims" ]] && path=("$PYENV_ROOT/shims" $path)
EOF

  install_managed_file "$tmp_file" "$TARGET_ENV_FILE"
  print_success "Managed PATH setup written to $TARGET_ENV_FILE"
}

write_managed_profile() {
  local tmp_file
  tmp_file="$(mktemp)"

  cat <<'EOF' >"$tmp_file"
# Managed by Artur's zsh-setup installer.
# This file is sourced from ~/.zprofile and can be regenerated safely.

[[ -r "$HOME/.config/artur-zsh-setup/env.zsh" ]] && source "$HOME/.config/artur-zsh-setup/env.zsh"
EOF

  install_managed_file "$tmp_file" "$TARGET_PROFILE_FILE"
  print_success "Managed login profile written to $TARGET_PROFILE_FILE"
}

write_managed_zshenv() {
  local tmp_file
  tmp_file="$(mktemp)"

  cat <<'EOF' >"$tmp_file"
# Managed by Artur's zsh-setup installer.
# This file is sourced from ~/.zshenv and can be regenerated safely.

# Ubuntu's /etc/zsh/zshrc runs compinit before ~/.zshrc, and Oh My Zsh runs it
# again with the full plugin fpath. Skip the first, redundant pass.
skip_global_compinit=1
EOF

  install_managed_file "$tmp_file" "$TARGET_ZSHENV_FILE"
  print_success "Managed zshenv written to $TARGET_ZSHENV_FILE"
}

update_loader_file() {
  local shell_file="$1"
  local managed_file="$2"
  local display_name="$3"
  local marker_start="# >>> artur-zsh-setup >>>"
  local marker_end="# <<< artur-zsh-setup <<<"
  local backup_suffix
  backup_suffix="$(date +%Y%m%d_%H%M%S)"
  local existing=""
  local tmp_file
  tmp_file="$(mktemp)"

  if run_as_target_user "[[ -f '$shell_file' ]]"; then
    existing="$(run_as_target_user "cat '$shell_file'")"
    if ! grep -Fq "$marker_start" <<<"$existing"; then
      run_as_target_user "cp '$shell_file' '$shell_file.backup.$backup_suffix'"
      print_success "Backed up existing $display_name to $display_name.backup.$backup_suffix"
    fi
  fi

  cat <<EOF >"$tmp_file"
$marker_start
[[ -f "$managed_file" ]] && source "$managed_file"
$marker_end
EOF

  if [[ -n "$existing" ]]; then
    if grep -Fq "$marker_start" <<<"$existing"; then
      existing="$(perl -0pe 's/\Q'"$marker_start"'\E.*?\Q'"$marker_end"'\E\n?//sm' <<<"$existing")"
    fi
    printf '%s\n\n' "$(cat "$tmp_file")" >"$tmp_file"
    printf '%s' "$existing" >>"$tmp_file"
  fi

  if is_root; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$tmp_file" "$shell_file"
  else
    install -m 0644 "$tmp_file" "$shell_file"
  fi

  rm -f "$tmp_file"
  print_success "$display_name updated with managed loader block"
}

disable_duplicate_oh_my_zsh() {
  # Earlier releases let the Oh My Zsh installer write its template ~/.zshrc on
  # fresh machines. Below the managed block it loaded Oh My Zsh a second time
  # with a different plugin list, which also rebuilt the completion dump on
  # every start. Only the untouched template is disabled; edited files get a
  # warning so user customisations are never dropped silently.
  local backup_suffix
  local tmp_file
  local result

  run_as_target_user "[[ -f '$TARGET_ZSHRC' ]]" || return 0
  tmp_file="$(mktemp)"
  run_as_target_user "cat '$TARGET_ZSHRC'" >"$tmp_file"

  result="$(perl -0 -e '
    local $/; my $text = <STDIN>;
    $text =~ s/^# >>> artur-zsh-setup >>>.*?^# <<< artur-zsh-setup <<<\n?//msg;
    my @loads = $text =~ /^[ \t]*(?:source|\.)[ \t]+["\x27]?\$\{?ZSH\}?\/oh-my-zsh\.sh/mg;
    exit 0 unless @loads;
    my @themes = $text =~ /^[ \t]*ZSH_THEME=/mg;
    my @plugins = $text =~ /^[ \t]*plugins=/mg;
    # Oh My Zsh settings above the load line (HIST_STAMPS, zstyle, DISABLE_*)
    # only take effect there; any active one makes the file customised.
    my ($before) = $text =~ /\A(.*?)^source \$ZSH\/oh-my-zsh\.sh$/ms;
    my @settings = grep { !/^[ \t]*(?:#|$)/ && !/^(?:export ZSH=.*|ZSH_THEME="robbyrussell"|plugins=\(git\))$/ }
      split /\n/, ($before // "");
    my $stock = @loads == 1 && @themes == 1 && @plugins == 1 && !@settings
      && $text =~ /^ZSH_THEME="robbyrussell"$/m
      && $text =~ /^plugins=\(git\)$/m
      && $text =~ /^source \$ZSH\/oh-my-zsh\.sh$/m;
    print $stock ? "stock" : "custom";
  ' <"$tmp_file")"

  case "$result" in
    stock)
      backup_suffix="$(date +%Y%m%d_%H%M%S)"
      run_as_target_user "cp '$TARGET_ZSHRC' '$TARGET_ZSHRC.backup.$backup_suffix'"
      perl -0pi -e 's/^(ZSH_THEME="robbyrussell"|plugins=\(git\)|source \$ZSH\/oh-my-zsh\.sh)$/# Disabled by artur-zsh-setup: the managed block already loads Oh My Zsh.\n# $1/mg' "$tmp_file"
      if is_root; then
        install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$tmp_file" "$TARGET_ZSHRC"
      else
        install -m 0644 "$tmp_file" "$TARGET_ZSHRC"
      fi
      print_success "Disabled the duplicate Oh My Zsh template in ~/.zshrc (backup: ~/.zshrc.backup.$backup_suffix)"
      ;;
    custom)
      print_warning "~/.zshrc loads Oh My Zsh a second time outside the managed block. Move its customisations into the managed setup and remove that 'source \$ZSH/oh-my-zsh.sh' line for a faster shell."
      ;;
  esac

  rm -f "$tmp_file"
}

install_apt_packages() {
  print_step "1" "Installing Ubuntu packages with apt"
  export DEBIAN_FRONTEND=noninteractive
  run_with_sudo apt-get update
  run_with_sudo apt-get install -y "${APT_PACKAGES[@]}"
  resolve_zsh_bin

  if command -v update-command-not-found >/dev/null 2>&1; then
    run_with_sudo update-command-not-found || print_warning "command-not-found database refresh failed"
  fi

  print_success "System packages installed"
}

configure_default_shell() {
  if [[ "$SKIP_SHELL_CHANGE" -eq 1 ]]; then
    print_warning "Skipping shell change by request"
    record_status skipped "default shell change"
    return
  fi

  if [[ "$TARGET_SHELL" == "$ZSH_BIN" ]]; then
    print_success "Default shell for $TARGET_USER is already zsh"
    record_status skipped "default shell change"
    return
  fi

  if ! prompt_yes_no "Change login shell for $TARGET_USER to $ZSH_BIN?" "y"; then
    print_warning "Default shell left unchanged"
    record_status skipped "default shell change"
    return
  fi

  if is_root; then
    chsh -s "$ZSH_BIN" "$TARGET_USER"
  else
    chsh -s "$ZSH_BIN"
  fi

  print_success "Default shell changed to zsh for $TARGET_USER"
  record_status installed "default shell change"
}

install_zsh_stack() {
  print_step "2" "Installing or updating Oh My Zsh, theme and plugins"
  install_oh_my_zsh
  git_sync_repo "Powerlevel10k" "$POWERLEVEL10K_REPO" "$TARGET_ZSH_CUSTOM/themes/powerlevel10k"
  git_sync_repo "fzf-tab" "$FZF_TAB_REPO" "$TARGET_ZSH_CUSTOM/plugins/fzf-tab"
  git_sync_repo "zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_REPO" "$TARGET_ZSH_CUSTOM/plugins/zsh-autosuggestions"
  git_sync_repo "zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$TARGET_ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  git_sync_repo "zsh-completions" "$ZSH_COMPLETIONS_REPO" "$TARGET_ZSH_CUSTOM/plugins/zsh-completions"
}

install_optional_tools() {
  if [[ "$SKIP_OPTIONAL_TOOLS" -eq 1 ]]; then
    print_warning "Skipping optional user tools by request"
    record_status skipped "pyenv"
    record_status skipped "bun"
    record_status skipped "uv"
    return
  fi

  print_step "3" "Installing or updating user-level tools"

  if prompt_yes_no "Install or update pyenv for $TARGET_USER?" "y"; then
    install_or_update_pyenv
  else
    EXPECT_PYENV=0
    record_status skipped "pyenv"
  fi

  if prompt_yes_no "Install or update Bun for $TARGET_USER? (required for the OpenTUI dashboard)" "y"; then
    install_or_update_bun
  else
    EXPECT_BUN=0
    EXPECT_DEVHUB=0
    record_status skipped "bun"
  fi

  if prompt_yes_no "Install or update uv for $TARGET_USER?" "y"; then
    install_or_update_uv
  else
    EXPECT_UV=0
    record_status skipped "uv"
  fi
}

install_ai_clis() {
  print_step "4" "Installing development and AI CLIs"

  if [[ "$SKIP_OPTIONAL_TOOLS" -eq 1 ]]; then
    print_warning "Skipping AI CLIs because optional tools were disabled"
    record_status skipped "Codex, Claude Code and OpenCode"
    return
  fi

  if ! prompt_yes_no "Install or update Codex, Claude Code and OpenCode for $TARGET_USER?" "y"; then
    EXPECT_AI=0
    record_status skipped "Codex, Claude Code and OpenCode"
    return
  fi

  if ! run_as_target_user "[[ -s '$TARGET_HOME/.nvm/nvm.sh' ]]"; then
    run_as_target_user "PROFILE=/dev/null curl -fsSL '$NVM_INSTALL_URL' | PROFILE=/dev/null bash"
    record_status installed "nvm"
  else
    record_status skipped "nvm already installed"
  fi

  run_as_target_user "export NVM_DIR='$TARGET_HOME/.nvm'; . '$TARGET_HOME/.nvm/nvm.sh'; nvm install --lts; nvm alias default 'lts/*'; npm install -g @openai/codex @anthropic-ai/claude-code"
  run_as_target_user "'$TARGET_HOME/.bun/bin/bun' add -g opencode-ai"
  print_success "Codex, Claude Code and OpenCode installed or updated"
}

install_devhub_assets() {
  print_step "5" "Installing devhub, tmux and learning content"
  local bin_dir="$TARGET_HOME/.local/bin"
  local content_dir="$TARGET_CONFIG_DIR/content"
  local app_dir="$TARGET_HOME/.local/share/devhub"

  if [[ "$EXPECT_DEVHUB" -eq 0 ]]; then
    print_warning "Skipping devhub because Bun was not selected"
    record_status skipped "devhub OpenTUI"
    return
  fi

  ensure_directory "$bin_dir"
  ensure_directory "$content_dir"
  ensure_directory "$app_dir"
  ensure_directory "$TARGET_HOME/repos"
  ensure_directory "$TARGET_HOME/school"
  ensure_directory "$TARGET_HOME/scratch"

  if is_root; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$SOURCE_DIR/bin/devhub" "$bin_dir/devhub"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$SOURCE_DIR/bin/devhub-core" "$bin_dir/devhub-core"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0755 "$SOURCE_DIR/bin/t" "$bin_dir/t"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/assets/tmux.conf" "$TARGET_HOME/.tmux.conf"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/assets/tmux-auto.zsh" "$TARGET_CONFIG_DIR/tmux-auto.zsh"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/assets/tmux-auto.bash" "$TARGET_CONFIG_DIR/tmux-auto.bash"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/content/tips.tsv" "$content_dir/tips.tsv"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/content/lessons.tsv" "$content_dir/lessons.tsv"
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$SOURCE_DIR/tui/package.json" "$SOURCE_DIR/tui/bun.lock" "$SOURCE_DIR/tui/index.ts" "$app_dir/"
    chown -R "$TARGET_USER:$TARGET_USER" "$app_dir"
  else
    install -m 0755 "$SOURCE_DIR/bin/devhub" "$bin_dir/devhub"
    install -m 0755 "$SOURCE_DIR/bin/devhub-core" "$bin_dir/devhub-core"
    install -m 0755 "$SOURCE_DIR/bin/t" "$bin_dir/t"
    install -m 0644 "$SOURCE_DIR/assets/tmux.conf" "$TARGET_HOME/.tmux.conf"
    install -m 0644 "$SOURCE_DIR/assets/tmux-auto.zsh" "$TARGET_CONFIG_DIR/tmux-auto.zsh"
    install -m 0644 "$SOURCE_DIR/assets/tmux-auto.bash" "$TARGET_CONFIG_DIR/tmux-auto.bash"
    install -m 0644 "$SOURCE_DIR/content/tips.tsv" "$content_dir/tips.tsv"
    install -m 0644 "$SOURCE_DIR/content/lessons.tsv" "$content_dir/lessons.tsv"
    install -m 0644 "$SOURCE_DIR/tui/package.json" "$SOURCE_DIR/tui/bun.lock" "$SOURCE_DIR/tui/index.ts" "$app_dir/"
  fi

  run_as_target_user "cd '$app_dir' && '$TARGET_HOME/.bun/bin/bun' install --production --frozen-lockfile"

  update_loader_file "$TARGET_ZSHRC" '$HOME/.config/artur-zsh-setup/zshrc.zsh' '~/.zshrc'
  if ! run_as_target_user "grep -Fq 'artur-zsh-setup/tmux-auto.zsh' '$TARGET_ZSHRC'"; then
    run_as_target_user "printf '\n[[ -f \"\$HOME/.config/artur-zsh-setup/tmux-auto.zsh\" ]] && source \"\$HOME/.config/artur-zsh-setup/tmux-auto.zsh\"\n' >> '$TARGET_ZSHRC'"
  fi
  if run_as_target_user "[[ -f '$TARGET_BASHRC' ]]" && ! run_as_target_user "grep -Fq 'artur-zsh-setup/tmux-auto.bash' '$TARGET_BASHRC'"; then
    run_as_target_user "printf '\n[[ -f \"\$HOME/.config/artur-zsh-setup/tmux-auto.bash\" ]] && source \"\$HOME/.config/artur-zsh-setup/tmux-auto.bash\"\n' >> '$TARGET_BASHRC'"
  fi
  run_as_target_user "tmux -L devhub-config-test -f '$TARGET_HOME/.tmux.conf' new-session -d -s test && tmux -L devhub-config-test kill-server"
  print_success "devhub and tmux workflow installed"
}

apply_shell_config() {
  print_step "6" "Writing shell configuration"
  write_managed_env
  write_managed_config
  write_managed_profile
  write_managed_zshenv
  update_loader_file "$TARGET_ZSHRC" '$HOME/.config/artur-zsh-setup/zshrc.zsh' '~/.zshrc'
  update_loader_file "$TARGET_ZPROFILE" '$HOME/.config/artur-zsh-setup/zprofile.zsh' '~/.zprofile'
  update_loader_file "$TARGET_ZSHENV" '$HOME/.config/artur-zsh-setup/zshenv.zsh' '~/.zshenv'
  disable_duplicate_oh_my_zsh
  refresh_generated_assets
}

zshrc_loads_oh_my_zsh_directly() {
  run_as_target_user "cat '$TARGET_ZSHRC' 2>/dev/null" | grep -Eq '^[[:space:]]*(source|\.)[[:space:]]+.?\$\{?ZSH\}?/oh-my-zsh\.sh'
}

verify_installation() {
  print_step "7" "Verifying installation"

  verify_check "zsh is installed" "command -v zsh >/dev/null 2>&1" || true
  verify_check "git is installed" "command -v git >/dev/null 2>&1" || true
  verify_check "curl is installed" "command -v curl >/dev/null 2>&1" || true
  verify_check "fzf is installed" "command -v fzf >/dev/null 2>&1" || true
  verify_check "gh is installed" "command -v gh >/dev/null 2>&1" || true
  verify_check "ripgrep is installed" "command -v rg >/dev/null 2>&1" || true
  verify_check "tmux is installed" "command -v tmux >/dev/null 2>&1" || true
  if [[ "$EXPECT_DEVHUB" -eq 1 ]]; then
    verify_check "devhub is installed" "run_as_target_user \"[[ -x '$TARGET_HOME/.local/bin/devhub' ]]\"" || true
    verify_check "devhub starts" "run_as_target_user \"'$TARGET_HOME/.local/bin/devhub' --version >/dev/null\"" || true
  fi
  if [[ "$EXPECT_AI" -eq 1 ]]; then
    verify_check "Codex is available" "run_as_target_user \"zsh -l -c 'command -v codex >/dev/null'\"" || true
    verify_check "Claude Code is available" "run_as_target_user \"zsh -l -c 'command -v claude >/dev/null'\"" || true
    verify_check "OpenCode is available" "run_as_target_user \"zsh -l -c 'command -v opencode >/dev/null'\"" || true
    verify_check "Node.js is on PATH without loading nvm" "run_as_target_user \"zsh -i -c 'command -v node >/dev/null && (( ! \\\$+functions[nvm_ls_current] ))'\"" || true
    verify_check "nvm loads on first use" "run_as_target_user \"zsh -i -c 'nvm --version >/dev/null'\"" || true
  fi
  verify_check "bat or batcat is installed" "command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1" || true
  verify_check "Oh My Zsh exists" "run_as_target_user \"[[ -d '$TARGET_ZSH' ]]\"" || true
  verify_check "Powerlevel10k exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/themes/powerlevel10k' ]]\"" || true
  verify_check "fzf-tab exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/fzf-tab' ]]\"" || true
  verify_check "zsh-autosuggestions exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-autosuggestions' ]]\"" || true
  verify_check "zsh-syntax-highlighting exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-syntax-highlighting' ]]\"" || true
  verify_check "zsh-completions exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-completions' ]]\"" || true
  verify_check "Managed config exists" "run_as_target_user \"[[ -f '$TARGET_CONFIG_FILE' ]]\"" || true
  verify_check "Managed login profile exists" "run_as_target_user \"[[ -f '$TARGET_PROFILE_FILE' ]]\"" || true
  verify_check "Managed PATH setup exists" "run_as_target_user \"[[ -f '$TARGET_ENV_FILE' ]]\"" || true
  verify_check "Managed config syntax is valid" "run_as_target_user \"zsh -n '$TARGET_CONFIG_FILE' && zsh -n '$TARGET_ENV_FILE'\"" || true
  verify_check "~/.zshrc loads Oh My Zsh only through the managed block" "! zshrc_loads_oh_my_zsh_directly" || true
  verify_check "Login zsh startup succeeds" "run_as_target_user \"zsh -l -c 'exit 0'\"" || true
  verify_check "Interactive zsh startup succeeds" "run_as_target_user \"zsh -i -c 'exit 0'\"" || true
  verify_check "git is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v git >/dev/null 2>&1'\"" || true
  verify_check "fzf is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v fzf >/dev/null 2>&1'\"" || true
  verify_check "gh is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v gh >/dev/null 2>&1'\"" || true

  if [[ "$EXPECT_PYENV" -eq 1 ]]; then
    verify_check "pyenv exists" "run_as_target_user \"[[ -x '$TARGET_HOME/.pyenv/bin/pyenv' ]]\"" || true
    verify_check "pyenv is available in login zsh" "run_as_target_user \"zsh -l -c 'command -v pyenv >/dev/null 2>&1 && pyenv --version >/dev/null 2>&1'\"" || true
    verify_check "pyenv is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v pyenv >/dev/null 2>&1 && pyenv --version >/dev/null 2>&1'\"" || true
  fi

  if [[ "$EXPECT_BUN" -eq 1 ]]; then
    verify_check "bun exists" "run_as_target_user \"[[ -x '$TARGET_HOME/.bun/bin/bun' ]]\"" || true
    verify_check "bun is available in login zsh" "run_as_target_user \"zsh -l -c 'command -v bun >/dev/null 2>&1 && bun --version >/dev/null 2>&1'\"" || true
    verify_check "bun is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v bun >/dev/null 2>&1 && bun --version >/dev/null 2>&1'\"" || true
  fi

  if [[ "$EXPECT_UV" -eq 1 ]]; then
    verify_check "uv exists" "run_as_target_user \"[[ -x '$TARGET_HOME/.local/bin/uv' ]]\"" || true
    verify_check "uvx exists" "run_as_target_user \"[[ -x '$TARGET_HOME/.local/bin/uvx' ]]\"" || true
    verify_check "uv completion exists" "run_as_target_user \"[[ -f '$TARGET_COMPLETIONS_DIR/_uv' ]]\"" || true
    verify_check "uv is available in login zsh" "run_as_target_user \"zsh -l -c 'command -v uv >/dev/null 2>&1 && uv --version >/dev/null 2>&1'\"" || true
    verify_check "uv is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v uv >/dev/null 2>&1 && uv --version >/dev/null 2>&1'\"" || true
  fi

  if [[ "${#SUMMARY_FAILURES[@]}" -gt 0 ]]; then
    return 1
  fi
}

maybe_run_p10k_configure() {
  print_step "8" "Finishing"

  if ! prompt_yes_no "Launch 'p10k configure' now for $TARGET_USER?" "n"; then
    print_success "Skipped Powerlevel10k configuration"
    return
  fi

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    print_warning "Cannot launch p10k configure in non-interactive mode"
    return
  fi

  run_as_target_user "zsh -lic 'p10k configure'"
}

print_summary() {
  local item

  echo
  echo -e "${BOLD}Summary${NC}"
  echo "========================================"

  if [[ "${#SUMMARY_INSTALLED[@]}" -gt 0 ]]; then
    echo "Installed:"
    for item in "${SUMMARY_INSTALLED[@]}"; do
      echo "  - $item"
    done
  fi

  if [[ "${#SUMMARY_UPDATED[@]}" -gt 0 ]]; then
    echo "Updated:"
    for item in "${SUMMARY_UPDATED[@]}"; do
      echo "  - $item"
    done
  fi

  if [[ "${#SUMMARY_SKIPPED[@]}" -gt 0 ]]; then
    echo "Skipped:"
    for item in "${SUMMARY_SKIPPED[@]}"; do
      echo "  - $item"
    done
  fi

  if [[ "${#SUMMARY_WARNINGS[@]}" -gt 0 ]]; then
    echo "Warnings:"
    for item in "${SUMMARY_WARNINGS[@]}"; do
      echo "  - $item"
    done
  fi

  if [[ "${#SUMMARY_FAILURES[@]}" -gt 0 ]]; then
    echo "Failed checks:"
    for item in "${SUMMARY_FAILURES[@]}"; do
      echo "  - $item"
    done
  fi

  echo
  echo "Target user : $TARGET_USER"
  echo "Target home : $TARGET_HOME"
  echo "Managed rc  : $TARGET_CONFIG_FILE"
  echo "Managed login: $TARGET_PROFILE_FILE"
  echo
  if [[ "${#SUMMARY_FAILURES[@]}" -eq 0 ]]; then
    echo "Next steps:"
    echo "  1. Open a new terminal, or run: exec zsh"
    echo "  2. If you skipped the prompt setup, run: p10k configure"
    echo "  3. Re-run health checks anytime with: bash $SCRIPT_NAME --doctor"
  else
    echo "The setup is not healthy yet. Fix the failed checks above, then re-run: bash $SCRIPT_NAME --doctor"
  fi
}

print_header
echo "Running as  : $(id -un)"
echo "Target user : $TARGET_USER"
echo "Target home : $TARGET_HOME"

if [[ "$DOCTOR_ONLY" -eq 1 ]]; then
  if command -v zsh >/dev/null 2>&1; then
    resolve_zsh_bin
  fi
  verify_installation || true
  print_summary
  if [[ "${#SUMMARY_FAILURES[@]}" -eq 0 ]]; then
    exit 0
  fi

  exit 1
fi

install_apt_packages
configure_default_shell
install_zsh_stack
install_optional_tools
install_ai_clis
apply_shell_config
install_devhub_assets
verify_installation || true
maybe_run_p10k_configure
print_summary

if [[ "${#SUMMARY_FAILURES[@]}" -eq 0 ]]; then
  exit 0
fi

exit 1
