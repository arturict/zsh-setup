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

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<EOF
Usage: $SCRIPT_NAME [options]

Options:
  --yes, -y             Accept defaults and avoid prompts where possible.
  --non-interactive     Disable prompts entirely.
  --doctor              Verify the current setup without changing anything.
  --skip-shell-change   Do not run chsh.
  --skip-optional-tools Skip pyenv, bun and uv.
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
TARGET_COMPLETIONS_DIR="$TARGET_CONFIG_DIR/completions"
TARGET_ZSHRC="$TARGET_HOME/.zshrc"
TARGET_ZPROFILE="$TARGET_HOME/.zprofile"
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

  if run_as_target_user "[[ -x '$TARGET_HOME/.local/bin/uv' ]]"; then
    if run_as_target_user "'$TARGET_HOME/.local/bin/uv' generate-shell-completion zsh > '$TARGET_COMPLETIONS_DIR/uv.zsh'"; then
      print_success "uv completion refreshed"
    else
      print_warning "Could not generate uv completion"
    fi

    if run_as_target_user "'$TARGET_HOME/.local/bin/uvx' --generate-shell-completion zsh > '$TARGET_COMPLETIONS_DIR/uvx.zsh'"; then
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

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
export PATH="$HOME/.local/bin:$PATH"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
export PYENV_ROOT="$HOME/.pyenv"

if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

export BUN_INSTALL="$HOME/.bun"
if [[ -d "$BUN_INSTALL/bin" ]]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}" "${XDG_STATE_HOME:-$HOME/.local/state}/zsh" 2>/dev/null || true

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
add_plugin_if_present "zsh-completions"
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

if [[ -r "$HOME/.config/artur-zsh-setup/completions/uv.zsh" ]]; then
  source "$HOME/.config/artur-zsh-setup/completions/uv.zsh"
fi

if [[ -r "$HOME/.config/artur-zsh-setup/completions/uvx.zsh" ]]; then
  source "$HOME/.config/artur-zsh-setup/completions/uvx.zsh"
fi

bindkey '^[[A' history-substring-search-up 2>/dev/null || true
bindkey '^[[B' history-substring-search-down 2>/dev/null || true

if [[ -r /usr/share/autojump/autojump.zsh ]]; then
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

if command -v pyenv >/dev/null 2>&1; then
  add_plugin_if_present "pyenv"
  eval "$(pyenv init - zsh)"
fi

export EDITOR="${EDITOR:-vim}"
EOF

  ensure_directory "$TARGET_CONFIG_DIR"

  if is_root; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$tmp_file" "$TARGET_CONFIG_FILE"
  else
    install -m 0644 "$tmp_file" "$TARGET_CONFIG_FILE"
  fi

  rm -f "$tmp_file"
  print_success "Managed zsh config written to $TARGET_CONFIG_FILE"
}

write_managed_profile() {
  local tmp_file
  tmp_file="$(mktemp)"

  cat <<'EOF' >"$tmp_file"
# Managed by Artur's zsh-setup installer.
# This file is sourced from ~/.zprofile and can be regenerated safely.

export PATH="$HOME/.local/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"

if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

export BUN_INSTALL="$HOME/.bun"
if [[ -d "$BUN_INSTALL/bin" ]]; then
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi
EOF

  ensure_directory "$TARGET_CONFIG_DIR"

  if is_root; then
    install -o "$TARGET_USER" -g "$TARGET_USER" -m 0644 "$tmp_file" "$TARGET_PROFILE_FILE"
  else
    install -m 0644 "$tmp_file" "$TARGET_PROFILE_FILE"
  fi

  rm -f "$tmp_file"
  print_success "Managed login profile written to $TARGET_PROFILE_FILE"
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

  if prompt_yes_no "Install or update bun for $TARGET_USER?" "y"; then
    install_or_update_bun
  else
    EXPECT_BUN=0
    record_status skipped "bun"
  fi

  if prompt_yes_no "Install or update uv for $TARGET_USER?" "y"; then
    install_or_update_uv
  else
    EXPECT_UV=0
    record_status skipped "uv"
  fi
}

apply_shell_config() {
  print_step "4" "Writing shell configuration"
  write_managed_config
  write_managed_profile
  update_loader_file "$TARGET_ZSHRC" '$HOME/.config/artur-zsh-setup/zshrc.zsh' '~/.zshrc'
  update_loader_file "$TARGET_ZPROFILE" '$HOME/.config/artur-zsh-setup/zprofile.zsh' '~/.zprofile'
  refresh_generated_assets
}

verify_installation() {
  print_step "5" "Verifying installation"

  verify_check "zsh is installed" "command -v zsh >/dev/null 2>&1" || true
  verify_check "git is installed" "command -v git >/dev/null 2>&1" || true
  verify_check "curl is installed" "command -v curl >/dev/null 2>&1" || true
  verify_check "fzf is installed" "command -v fzf >/dev/null 2>&1" || true
  verify_check "gh is installed" "command -v gh >/dev/null 2>&1" || true
  verify_check "ripgrep is installed" "command -v rg >/dev/null 2>&1" || true
  verify_check "tmux is installed" "command -v tmux >/dev/null 2>&1" || true
  verify_check "bat or batcat is installed" "command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1" || true
  verify_check "Oh My Zsh exists" "run_as_target_user \"[[ -d '$TARGET_ZSH' ]]\"" || true
  verify_check "Powerlevel10k exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/themes/powerlevel10k' ]]\"" || true
  verify_check "fzf-tab exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/fzf-tab' ]]\"" || true
  verify_check "zsh-autosuggestions exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-autosuggestions' ]]\"" || true
  verify_check "zsh-syntax-highlighting exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-syntax-highlighting' ]]\"" || true
  verify_check "zsh-completions exists" "run_as_target_user \"[[ -d '$TARGET_ZSH_CUSTOM/plugins/zsh-completions' ]]\"" || true
  verify_check "Managed config exists" "run_as_target_user \"[[ -f '$TARGET_CONFIG_FILE' ]]\"" || true
  verify_check "Managed login profile exists" "run_as_target_user \"[[ -f '$TARGET_PROFILE_FILE' ]]\"" || true
  verify_check "Managed config syntax is valid" "run_as_target_user \"zsh -n '$TARGET_CONFIG_FILE'\"" || true
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
    verify_check "uv completion exists" "run_as_target_user \"[[ -f '$TARGET_COMPLETIONS_DIR/uv.zsh' ]]\"" || true
    verify_check "uv is available in login zsh" "run_as_target_user \"zsh -l -c 'command -v uv >/dev/null 2>&1 && uv --version >/dev/null 2>&1'\"" || true
    verify_check "uv is available inside zsh" "run_as_target_user \"zsh -i -c 'command -v uv >/dev/null 2>&1 && uv --version >/dev/null 2>&1'\"" || true
  fi

  if [[ "${#SUMMARY_FAILURES[@]}" -gt 0 ]]; then
    return 1
  fi
}

maybe_run_p10k_configure() {
  print_step "6" "Finishing"

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
apply_shell_config
verify_installation || true
maybe_run_p10k_configure
print_summary

if [[ "${#SUMMARY_FAILURES[@]}" -eq 0 ]]; then
  exit 0
fi

exit 1
