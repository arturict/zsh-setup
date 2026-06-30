# devhub Setup

Ein reproduzierbares Development-Setup für Ubuntu, WSL und Windows. Ein Installationsbefehl richtet Shell, tmux, Developer-Werkzeuge, AI-CLIs und die geführte `devhub`-Oberfläche ein.

## Installation

Ubuntu oder WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/setup.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/arturict/zsh-setup/main/setup.ps1 | iex
```

Der Installer kann später erneut ausgeführt werden. Bestehende Shell-Dateien werden gesichert und nur um kleine, markierte Loader ergänzt. Auth-Tokens und API-Keys kommen niemals ins Repository.

## Geführte Bedienung

```bash
devhub
```

öffnet das Fullscreen-Dashboard mit Systemstatus, zufälligen Command-Tipps, Kurzlektionen und direkten Aktionen.

```bash
devhub doctor       # Installation und Logins prüfen
devhub tmux         # tmux-Kurzübersicht
devhub sessions     # Projekt-Workspace öffnen
devhub learn        # geführte Lektionen
devhub tips         # Command-Bibliothek
devhub auth         # sichere Login-Anleitung
devhub update       # alles aktualisieren
```

## Arbeiten mit tmux

Im Projekt genügt:

```bash
t
```

Die Session wird automatisch nach dem aktuellen Verzeichnis benannt und entweder erstellt oder fortgesetzt. Bei interaktiven SSH-Logins landest du automatisch in `main`.

| Tastenkürzel | Funktion |
|---|---|
| `Ctrl-a s` | Sessions und Fenster auswählen |
| `Ctrl-a c` | neues Fenster |
| `Ctrl-a \|` | seitlich teilen |
| `Ctrl-a -` | oben/unten teilen |
| `Ctrl-a h/j/k/l` | zwischen Bereichen wechseln |
| `Ctrl-a d` | trennen; Prozesse laufen weiter |

Die Statusleiste zeigt immer Hostname, Session, Fenster, aktuelles Verzeichnis und Zeit. Dadurch ist bei mehreren Tailscale-Maschinen sofort sichtbar, wo du gerade arbeitest.

## Installierte Werkzeuge

Ubuntu/WSL erhält unter anderem Zsh, Powerlevel10k, GitHub CLI, fzf, ripgrep, bat, tmux, Node LTS, Bun, uv, pyenv, Codex, Claude Code und OpenCode. Ausserdem werden `~/repos`, `~/school` und `~/scratch` angelegt.

Windows erhält Windows Terminal, PowerShell, Git, GitHub CLI, VS Code und Tailscale. WSL/Ubuntu bleibt die eigentliche Linux-Entwicklungsumgebung.

## Logins

Auf jeder neuen Maschine einmalig:

```bash
gh auth login
codex login
opencode auth login
claude /login
devhub doctor
```

Der Installer zeigt fehlende Logins an, kopiert aber bewusst keine Credentials zwischen Geräten.
