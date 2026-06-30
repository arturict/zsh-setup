# devhub setup

One-command development environment for Ubuntu, WSL and Windows. It installs a consistent shell, tmux workflow, developer tools, AI CLIs and the interactive `devhub` learning dashboard.

## Install

Ubuntu or WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/setup.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/arturict/zsh-setup/main/setup.ps1 | iex
```

The scripts are safe to run again for updates. Existing shell files are backed up before the managed loader is added. Optional components are presented for confirmation instead of silently installed, including when `setup.sh` is piped through `curl`. Authentication secrets are never stored in this repository.

## What it installs

Ubuntu and WSL:

- Zsh, Oh My Zsh, Powerlevel10k and completion plugins
- Git, GitHub CLI, fzf, ripgrep, bat, tmux and build tools
- Node.js LTS through nvm, Bun, uv and pyenv
- Codex CLI, Claude Code and OpenCode
- `~/repos`, `~/school` and `~/scratch`
- a persistent, visually clear tmux configuration
- `devhub` and the `t` project-session command

Windows:

- Windows Terminal, PowerShell, Git, GitHub CLI, VS Code and Tailscale via winget
- Ubuntu via WSL when WSL is missing
- the PowerShell edition of `devhub`

Linux development tools stay inside Ubuntu/WSL. Windows remains the host for Windows Terminal, VS Code, Tailscale and WSL lifecycle management.

## Guided CLI

Open the fullscreen dashboard, built with [OpenTUI](https://opentui.com/):

```bash
devhub
```

Direct commands:

```bash
devhub doctor       # installation and auth health
devhub tmux         # tmux cheat sheet
devhub sessions     # open the current project workspace
devhub learn        # guided short lessons
devhub tips         # searchable command library
devhub auth         # login instructions without exposing tokens
devhub update       # pull a clean copy and re-run setup
```

The dashboard rotates practical reminders and tracks completed lessons locally under `~/.local/state/devhub`. It never uploads usage data.

## Installation choices

The installer asks before optional or disruptive changes, including AI CLIs, pyenv, Bun, uv, Windows applications and installing Ubuntu in WSL. `--yes` is the explicit unattended opt-in and accepts the documented defaults. The minimal shell and verification dependencies remain automatic on Ubuntu.

## tmux workflow

Inside any project:

```bash
t
```

This creates or resumes a session named after the current directory. Interactive SSH logins automatically create or resume the `main` session.

```bash
t ls                 # list sessions (does not create a session named "ls")
t NAME               # open or create a named session
t kill NAME          # remove a session
```

| Shortcut | Action |
|---|---|
| `Ctrl-a s` | select sessions and windows |
| `Ctrl-a c` | new window in the current directory |
| `Ctrl-a \|` | split left/right |
| `Ctrl-a -` | split top/bottom |
| `Ctrl-a h/j/k/l` | move between panes |
| `Ctrl-a d` | detach while processes keep running |
| `Ctrl-a r` | reload configuration |

The status bar always shows the machine hostname, session, window, current path and time. This is important when working across WSL and multiple Tailscale machines.

## Authentication

Installers deliberately do not copy or commit credentials. Log in once on each machine:

```bash
gh auth login
codex login
opencode auth login
claude /login
devhub doctor
```

Subscription sessions and API keys remain in each tool's protected user configuration.

## Installer options

```bash
bash setup.sh --yes
bash setup.sh --non-interactive
bash setup.sh --doctor
bash setup.sh --skip-shell-change
bash setup.sh --skip-optional-tools
```

## Managed files

```text
~/.config/artur-zsh-setup/
├── zshrc.zsh
├── zprofile.zsh
├── tmux-auto.zsh
├── tmux-auto.bash
└── content/
~/.local/bin/devhub
~/.local/bin/t
~/.tmux.conf
```

The installer only adds marked loader blocks to `.zshrc`/`.zprofile` and one guarded tmux loader to `.bashrc` where applicable.

## Repository layout

```text
assets/                 managed tmux and shell integration
bin/                    devhub and helper commands
content/                tips and guided lessons
tui/                    OpenTUI TypeScript application
install-zsh-setup.sh    Ubuntu/WSL implementation
setup.sh                Linux entry point
setup.ps1               Windows entry point
```

Supported systems: Ubuntu 22.04+, Ubuntu 24.04+, Ubuntu 26.04 and WSL running Ubuntu. Other Linux distributions intentionally fail with a clear message.
