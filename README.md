# Ubuntu Zsh Setup

Personal Zsh setup for Ubuntu 22.04+ with:

- `zsh`
- Oh My Zsh
- Powerlevel10k
- `fzf-tab`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `zsh-completions`
- `gh`
- `tmux`
- `bat`
- `ripgrep`
- `autojump`
- `pyenv`
- `bun`
- `uv`

The installer is now designed to be safe to run with `sudo` while still installing user-level tools and shell config for the original invoking user.

## What Changed

- Uses `apt-get` for system packages and installs them with `sudo`
- Installs Oh My Zsh, plugins, `pyenv`, `bun`, and `uv` for the target user
- Detects the target account from `SUDO_USER`
- Updates existing git-based tools instead of only skipping them
- Keeps `~/.zshrc` clean by adding a small loader block instead of overwriting the whole file
- Writes the managed config to `~/.config/artur-zsh-setup/zshrc.zsh`
- Adds a few prompts so the install stays interactive without being noisy
- Adds a `--doctor` health check mode so you can verify the setup later without reinstalling
- Refreshes `uv`/`uvx` completions and enables a more polished completion and history setup

## Recommended Install

Remote:

```bash
curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/install-zsh-setup.sh | sudo bash
```

Local:

```bash
sudo bash install-zsh-setup.sh
```

If you run the script as root without `sudo`, set the target user explicitly:

```bash
TARGET_USER=artur sudo -E bash install-zsh-setup.sh
```

## Flags

```bash
sudo bash install-zsh-setup.sh --yes
sudo bash install-zsh-setup.sh --non-interactive
sudo bash install-zsh-setup.sh --doctor
sudo bash install-zsh-setup.sh --skip-shell-change
sudo bash install-zsh-setup.sh --skip-optional-tools
```

## Installed Components

System packages via `apt`:

```bash
autojump bat build-essential ca-certificates command-not-found curl fzf gh git \
libbz2-dev libffi-dev liblzma-dev libncursesw5-dev libreadline-dev libsqlite3-dev \
libssl-dev libxml2-dev libxmlsec1-dev libzstd-dev make patch python3-pip \
python3-venv ripgrep tk-dev tmux unzip xz-utils zlib1g-dev zsh
```

User-level components:

- Oh My Zsh
- Powerlevel10k
- `fzf-tab`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `zsh-completions`
- `pyenv`
- `bun`
- `uv`

## Configuration Layout

The installer writes:

- `~/.config/artur-zsh-setup/zshrc.zsh`
- `~/.config/artur-zsh-setup/zprofile.zsh`
- `~/.config/artur-zsh-setup/completions/uv.zsh`
- `~/.config/artur-zsh-setup/completions/uvx.zsh`
- a loader block at the top of `~/.zshrc`
- a loader block at the top of `~/.zprofile`

If `~/.zshrc` already exists and has not been managed by this installer before, it is backed up first.

## Tool Notes

- `pyenv` is installed in `~/.pyenv`
- `bun` is installed in `~/.bun`
- `uv` is installed in `~/.local/bin`
- `pyenv` is added to `PATH` correctly before initialization
- `pyenv` gets its optional native extension build when possible for faster startup
- `fzf` shell bindings are loaded from Ubuntu's packaged examples when available
- `uv` and `uvx` shell completions are generated into the managed config directory
- history is moved into `~/.local/state/zsh/history` with modern duplicate filtering and sharing enabled
- login-shell PATH bootstrapping lives in a managed `~/.zprofile` include so `pyenv` works cleanly in login shells too

## After Install

Open a new terminal, or run:

```bash
exec zsh
```

Then optionally configure the prompt:

```bash
p10k configure
```

Quick checks:

```bash
bun --version
uv --version
pyenv --version
bash install-zsh-setup.sh --doctor
git checkout <Tab>
j src
```

## Upstream References

These upstream install locations were checked when updating this repo on March 17, 2026:

- Oh My Zsh install script: `https://ohmyz.sh/#install`
- `uv` install docs: `https://docs.astral.sh/uv/getting-started/installation/`
- Bun install docs: `https://bun.com/docs/installation`
- pyenv install docs: `https://github.com/pyenv/pyenv?tab=readme-ov-file#installation`

## Tested On

- Ubuntu 24.04 LTS (clean container install + doctor verification)
- Ubuntu 22.04+ (primary target)
