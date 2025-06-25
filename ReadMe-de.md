# Zsh Setup

Dies ist mein persönliches Zsh-Setup für eine angenehme Developer Experience im Terminal.  
🇺🇸 For English version click [here](./README.md)

## ⚡ Schnellinstallation (Empfohlen)

Führe diesen einen Befehl aus, um alles automatisch zu installieren:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/install.sh)
```

Nach der Installation führe `exec zsh` aus, um dein neues Setup zu verwenden!

## 📋 Was ist enthalten

- **Zsh** mit **Oh My Zsh** Framework
- **Powerlevel10k** Theme für ein schönes und informatives Prompt
- **Wichtige Plugins** für erhöhte Produktivität:
  - `fzf-tab` - Interaktive Fuzzy-Tab-Vervollständigung
  - `zsh-autosuggestions` - Fish-ähnliche Autosuggestions
  - `zsh-syntax-highlighting` - Syntax-Highlighting für Befehle
  - `zsh-completions` - Zusätzliche Vervollständigungsdefinitionen
  - `autojump` - Intelligente Verzeichnisnavigation
  - Und viele weitere nützliche Plugins!

## 🔧 Manuelle Installation

Falls du Schritt für Schritt installieren möchtest:

### Voraussetzungen
- **Ubuntu/Debian** System mit `apt` Paketmanager
- **Internetverbindung** zum Herunterladen von Paketen und Themes

### Schritte

1. **Installiere zsh** (falls noch nicht vorhanden):
   ```bash
   sudo apt install zsh
   ```

2. **Installiere oh-my-zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

3. **Installiere powerlevel10k Theme**:
   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

4. **Installiere benötigte Plugins**:
   ```bash
   ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
   
   git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
   git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
   sudo apt install autojump
   ```

5. **Ersetze deine .zshrc**:
   ```bash
   # Sichere deine bestehende .zshrc (optional)
   cp ~/.zshrc ~/.zshrc.backup
   
   # Lade die neue .zshrc herunter und wende sie an
   curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/.zshrc -o ~/.zshrc
   ```

6. **Setze zsh als Standard-Shell** (optional):
   ```bash
   chsh -s $(which zsh)
   ```

7. **Shell neu starten**:
   ```bash
   exec zsh
   ```

## 🎨 Erster Start

Beim ersten Start von zsh mit diesem Setup:
1. Der **Powerlevel10k Konfigurationsassistent** startet automatisch
2. Folge den Anweisungen, um das Aussehen deines Prompts anzupassen
3. Deine Auswahl wird in `~/.p10k.zsh` gespeichert

## 🛠️ Anpassung

- Bearbeite `~/.zshrc` um Plugins, Aliase und Einstellungen zu ändern
- Führe `p10k configure` aus, um dein Prompt-Theme jederzeit neu zu konfigurieren
- Füge deine eigenen Aliase und Funktionen am Ende der `.zshrc` Datei hinzu

## 🆘 Fehlerbehebung

**Theme nicht gefunden Fehler?**
- Stelle sicher, dass du das powerlevel10k Theme installiert hast (Schritt 3 der manuellen Installation)

**Plugins funktionieren nicht?**
- Überprüfe, dass alle Plugins in `~/.oh-my-zsh/custom/plugins/` installiert sind
- Prüfe, dass die Plugin-Namen in der `.zshrc` mit den Ordnernamen übereinstimmen

**Immer noch Probleme?**
- Probiere den automatischen Installer: er kümmert sich korrekt um alle Abhängigkeiten
- Öffne ein Issue auf GitHub mit deiner Fehlermeldung

---

Genieße deine verbesserte Terminal-Erfahrung! 🚀
