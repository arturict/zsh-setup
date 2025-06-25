# Zsh Setup

Dies ist mein persönliches Zsh-Setup für eine angenehme Developer Experience im Terminal.

## Voraussetzungen

- **zsh** muss installiert sein.
- [oh-my-zsh](https://ohmyz.sh/) sollte installiert sein.

## Installation

1. **Installiere zsh** (falls noch nicht vorhanden):

    ```bash
    sudo apt install zsh
    ```

2. **Installiere oh-my-zsh**:

    ```bash
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

3. **.zshrc ersetzen**:

    Ersetze den Inhalt deiner bestehenden `~/.zshrc`-Datei durch die `.zshrc`-Datei aus diesem Repository.

4. **Plugins installieren**:

    Führe folgende Befehle aus, um alle benötigten Plugins zu installieren:

    ```bash
    SH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

    git clone https://github.com/Aloxaf/fzf-tab           $SH_CUSTOM/plugins/fzf-tab
    git clone https://github.com/zsh-users/zsh-autosuggestions $SH_CUSTOM/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $SH_CUSTOM/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions $SH_CUSTOM/plugins/zsh-completions
    sudo apt install autojump
    ```

5. **Shell neu starten**:

    ```bash
    exec zsh
    ```

Jetzt ist dein Zsh wie in diesem Repository eingerichtet. Viel Spaß!
