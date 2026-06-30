#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="https://github.com/arturict/zsh-setup.git"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  SOURCE_DIR=""
fi

if [[ ${OS:-} == Windows_NT ]]; then
  printf 'Windows erkannt. Starte in PowerShell:\n'
  printf '  irm https://raw.githubusercontent.com/arturict/zsh-setup/main/setup.ps1 | iex\n'
  exit 1
fi

if [[ -z "$SOURCE_DIR" || ! -f "$SOURCE_DIR/install-zsh-setup.sh" || ! -d "$SOURCE_DIR/assets" ]]; then
  if ! command -v git >/dev/null 2>&1; then
    command -v apt-get >/dev/null 2>&1 || { printf 'git is required to download the setup.\n' >&2; exit 1; }
    if [[ $(id -u) -eq 0 ]]; then apt-get update && apt-get install -y git;
    else sudo apt-get update && sudo apt-get install -y git; fi
  fi
  SOURCE_DIR="$(mktemp -d)"
  trap 'rm -rf "$SOURCE_DIR"' EXIT
  git clone --depth=1 "$REPO_URL" "$SOURCE_DIR/repo"
  SOURCE_DIR="$SOURCE_DIR/repo"
fi

if ! grep -Eqi 'ubuntu|debian' /etc/os-release 2>/dev/null; then
  printf 'Unsupported Linux distribution. This setup currently supports Ubuntu/WSL only.\n' >&2
  exit 1
fi

export DEVHUB_SOURCE_DIR="$SOURCE_DIR"
if [[ -t 1 && -r /dev/tty && " $* " != *" --non-interactive "* ]]; then
  exec bash "$SOURCE_DIR/install-zsh-setup.sh" "$@" </dev/tty
fi
exec bash "$SOURCE_DIR/install-zsh-setup.sh" "$@"
