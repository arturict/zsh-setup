# Ubuntu Installation Guide – Artur's Z‑Shell Setup

> Dieses How‑to beschreibt **ausschliesslich** die Installation meines persönlichen Zsh‑Workflows unter **Ubuntu 22.04 LTS (oder neuer)**.
> Powerlevel10k Prompt, Oh My Zsh und sämtliche Plugins für Laravel, Git, Docker, Node/React und Python werden eingerichtet.

---

## Schritt 0 – Voraussetzungen

```bash
sudo apt update
sudo apt install -y zsh git curl fzf autojump \
  build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev python3-pip
```

| Tool          | Zweck                       |
| ------------- | --------------------------- |
| `zsh`         | moderne Shell               |
| `git`, `curl` | Installer/Clone             |
| `fzf`         | fuzzy Search & fzf‑tab      |
| `autojump`    | schnelles Directory Hopping |
| Build‑Libs    | notwendig für **pyenv**     |

---

## Schritt 1 – Zsh als Standardshell

```bash
chsh -s $(which zsh)
exec zsh   # oder neues Terminal öffnen
```

---

## Schritt 2 – Oh My Zsh installieren

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## Schritt 3 – Powerlevel10k Theme holen

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

---

## Schritt 4 – Externe Plugins klonen

```bash
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

git clone https://github.com/Aloxaf/fzf-tab                  $ZSH_CUSTOM/plugins/fzf-tab
git clone https://github.com/zsh-users/zsh-autosuggestions   $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                                                             $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions       $ZSH_CUSTOM/plugins/zsh-completions
```

---

## Schritt 5 – GitHub‑CLI & pyenv (optional aber empfohlen)

```bash
sudo apt install gh
curl https://pyenv.run | bash
```

Folge den Anweisungen von pyenv, um die nötigen `eval`‑Zeilen in deine `.zshrc` aufzunehmen.

---

## Schritt 6 – `.zshrc` übernehmen

Erstelle/ersetze **`~/.zshrc`** mit folgendem Basis‑Snippet (gekürzt):

```zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

plugins=(
  gitfast docker laravel composer node yarn pyenv gh
  fzf-tab zsh-autosuggestions zsh-syntax-highlighting
  history-substring-search alias-finder autojump
  zsh-completions command-not-found colored-man-pages
)

source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
```

> Vollständige Aliasse und Config findest du im Repository oder in der alten README.

---

## Schritt 7 – Prompt konfigurieren & testen

```bash
p10k configure
exec zsh
```

Wenn keine Fehlermeldungen erscheinen und der Prompt hübsch aussieht, ist Artur's Setup einsatzbereit ✅

---

### Schnelltest

```bash
git checkout <Tab>        # sollte interaktiv via fzf erscheinen
j src                     # wechselt per autojump in letztes „src“‑Verzeichnis
art migrate               # Laravel‑Alias läuft
```
