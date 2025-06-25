

# Zsh Setup

This is my personal Zsh setup for a pleasant developer experience in the terminal.  
🇩🇪 Für die deutsche Version klicke [hier](./ReadMe-de.md)

## ⚡ Quick Install (Recommended)

Run this single command to install everything automatically:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/install.sh)
```

After installation, run `exec zsh` to start using your new setup!

## 📋 What's Included

- **Zsh** with **Oh My Zsh** framework
- **Powerlevel10k** theme for a beautiful and informative prompt
- **Essential plugins** for enhanced productivity:
  - `fzf-tab` - Interactive fuzzy tab completion
  - `zsh-autosuggestions` - Fish-like autosuggestions
  - `zsh-syntax-highlighting` - Syntax highlighting for commands
  - `zsh-completions` - Additional completion definitions
  - `autojump` - Smart directory navigation
  - And many more useful plugins!

## 🔧 Manual Installation

If you prefer to install step by step:

### Requirements
- **Ubuntu/Debian** system with `apt` package manager
- **Internet connection** for downloading packages and themes

### Steps

1. **Install zsh** (if not already installed):
   ```bash
   sudo apt install zsh
   ```

2. **Install oh-my-zsh**:
   ```bash
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

3. **Install powerlevel10k theme**:
   ```bash
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
   ```

4. **Install required plugins**:
   ```bash
   ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
   
   git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
   git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
   sudo apt install autojump
   ```

5. **Replace your .zshrc**:
   ```bash
   # Backup your existing .zshrc (optional)
   cp ~/.zshrc ~/.zshrc.backup
   
   # Download and apply the new .zshrc
   curl -fsSL https://raw.githubusercontent.com/arturict/zsh-setup/main/.zshrc -o ~/.zshrc
   ```

6. **Set zsh as default shell** (optional):
   ```bash
   chsh -s $(which zsh)
   ```

7. **Restart your shell**:
   ```bash
   exec zsh
   ```

## 🎨 First Run

When you first run zsh with this setup:
1. **Powerlevel10k configuration wizard** will start automatically
2. Follow the prompts to customize your prompt appearance
3. Your choices will be saved to `~/.p10k.zsh`

## 🛠️ Customization

- Edit `~/.zshrc` to modify plugins, aliases, and settings
- Run `p10k configure` anytime to reconfigure your prompt theme
- Add your own aliases and functions to the bottom of the `.zshrc` file

## 🆘 Troubleshooting

**Theme not found error?**
- Make sure you installed powerlevel10k theme (step 3 in manual installation)

**Plugins not working?**
- Verify all plugins are installed in `~/.oh-my-zsh/custom/plugins/`
- Check that plugin names in `.zshrc` match the folder names

**Still having issues?**
- Try the automatic installer: it handles all dependencies correctly
- Open an issue on GitHub with your error message

---

Enjoy your enhanced terminal experience! 🚀
