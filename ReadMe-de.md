# Artur Shell Setup

Persoenliches Shell-Setup fuer Ubuntu 22.04+ und Windows.

Unter Ubuntu installiert es ein Zsh-Setup mit:

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

Unter Windows installiert es ein modernes PowerShell/Windows-Terminal-Setup mit:

- PowerShell 7
- Windows Terminal
- Oh My Posh mit Powerlevel10k-aehnlichem Theme
- PSReadLine History und Predictions
- `Terminal-Icons`
- `posh-git`
- `PSFzf`
- `CompletionPredictor`
- `fzf`
- `zoxide`
- `gh`
- `bat`
- `ripgrep`
- `bun`
- `uv`

Der Ubuntu-Installer ist so gebaut, dass er sauber mit `sudo` laeuft, Systempakete mit Root installiert und trotzdem alle User-Komponenten fuer den aktuell aufrufenden Benutzer einrichtet. Der Windows-Installer nutzt `winget` fuer Anwendungen und `Install-Module -Scope CurrentUser` fuer PowerShell-Module.

## Was Jetzt Besser Laeuft

- Systempakete werden per `apt-get` mit `sudo` installiert
- Oh My Zsh, Plugins, `pyenv`, `bun` und `uv` werden fuer den Ziel-User installiert
- Der Ziel-User wird ueber `SUDO_USER` erkannt
- Bereits vorhandene Git-Repositories werden aktualisiert statt nur uebersprungen
- `~/.zshrc` wird nicht mehr komplett ersetzt
- Die gemanagte Zsh-Konfiguration liegt sauber in `~/.config/artur-zsh-setup/zshrc.zsh`
- Der Ablauf ist etwas interaktiver, bleibt aber skriptfreundlich
- Ein `--doctor`-Modus prueft spaeter den Setup-Zustand ohne Neuinstallation
- `uv`/`uvx`-Completions sowie History- und Completion-UX werden moderner eingerichtet

## Empfohlene Installation

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/arturict/zsh-setup/main/install.ps1 | iex
```

Windows lokal:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

PowerShell 7 lokal:

```powershell
pwsh -ExecutionPolicy Bypass -File ./install.ps1
```

Ubuntu remote:

```bash
curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/install-zsh-setup.sh | sudo bash
```

Lokal:

```bash
sudo bash install-zsh-setup.sh
```

Falls du als Root ohne `sudo` startest, setze den Ziel-User explizit:

```bash
TARGET_USER=artur sudo -E bash install-zsh-setup.sh
```

## Optionen

Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Yes
powershell -ExecutionPolicy Bypass -File .\install.ps1 -NonInteractive
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Doctor
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkipWinget
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkipModules
powershell -ExecutionPolicy Bypass -File .\install.ps1 -SkipOptionalTools
```

Ubuntu:

```bash
sudo bash install-zsh-setup.sh --yes
sudo bash install-zsh-setup.sh --non-interactive
sudo bash install-zsh-setup.sh --doctor
sudo bash install-zsh-setup.sh --skip-shell-change
sudo bash install-zsh-setup.sh --skip-optional-tools
```

## Was Installiert Wird

Systempakete via `apt`:

```bash
autojump bat build-essential ca-certificates command-not-found curl fzf gh git \
libbz2-dev libffi-dev liblzma-dev libncursesw5-dev libreadline-dev libsqlite3-dev \
libssl-dev libxml2-dev libxmlsec1-dev libzstd-dev make patch python3-pip \
python3-venv ripgrep tk-dev tmux unzip xz-utils zlib1g-dev zsh
```

User-Komponenten:

- Oh My Zsh
- Powerlevel10k
- `fzf-tab`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `zsh-completions`
- `pyenv`
- `bun`
- `uv`

## Konfigurationslayout

Der Ubuntu-Installer schreibt:

- `~/.config/artur-zsh-setup/zshrc.zsh`
- `~/.config/artur-zsh-setup/zprofile.zsh`
- `~/.config/artur-zsh-setup/completions/uv.zsh`
- `~/.config/artur-zsh-setup/completions/uvx.zsh`
- einen kleinen Loader-Block oben in `~/.zshrc`
- einen kleinen Loader-Block oben in `~/.zprofile`

Wenn `~/.zshrc` schon existiert und noch nicht von diesem Installer verwaltet wurde, wird vorher ein Backup angelegt.

Der Windows-Installer schreibt:

- `~/.config/artur-powershell-setup/profile.ps1`
- einen Loader-Block in das Current-User-PowerShell-Profil
- einen Loader-Block in das Current-User-All-Hosts-PowerShell-Profil
- PowerShell-History nach `~/.local/state/powershell/history.txt`

Wenn ein PowerShell-Profil schon existiert und noch nicht von diesem Installer verwaltet wurde, wird vorher ein Backup angelegt.

## Hinweise Zu Den Tools

- `pyenv` landet in `~/.pyenv`
- `bun` landet in `~/.bun`
- `uv` landet in `~/.local/bin`
- `pyenv` wird korrekt vor der Initialisierung in den `PATH` aufgenommen
- Die optionale native `pyenv`-Erweiterung wird wenn moeglich mitgebaut und beschleunigt Starts
- `fzf`-Bindings werden von Ubuntus Paketpfaden geladen, falls vorhanden
- `uv`- und `uvx`-Completions werden in das gemanagte Verzeichnis erzeugt
- Die Zsh-History liegt sauber in `~/.local/state/zsh/history` mit besserer Duplikat-Filterung
- Login-Shell-Pfade laufen ueber ein gemanagtes Include in `~/.zprofile`, damit `pyenv` dort sauber verfuegbar ist

## Nach Der Installation

Windows:

Neuen Windows-Terminal-Tab oeffnen oder:

```powershell
. $PROFILE
```

Schnelltests:

```powershell
bun --version
uv --version
oh-my-posh --version
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Doctor
j src
```

Ubuntu:

Neues Terminal oeffnen oder:

```bash
exec zsh
```

Danach optional:

```bash
p10k configure
```

Schnelltests:

```bash
bun --version
uv --version
pyenv --version
bash install-zsh-setup.sh --doctor
git checkout <Tab>
j src
```

## Upstream-Referenzen

Diese Upstream-Pfade wurden beim Update des Repos am 17. Maerz 2026 geprueft:

- Oh My Zsh Install-Skript: `https://ohmyz.sh/#install`
- `uv` Install-Doku: `https://docs.astral.sh/uv/getting-started/installation/`
- Bun Install-Doku: `https://bun.com/docs/installation`
- pyenv Install-Doku: `https://github.com/pyenv/pyenv?tab=readme-ov-file#installation`

## Getestet Auf

- Ubuntu 24.04 LTS (saubere Container-Installation + Doctor-Verifikation)
- Ubuntu 22.04+ (Haupt-Ziel)
- Windows 11 mit Windows PowerShell 5.1 und PowerShell 7
