# User Account Setup Scripts

Idempotent scripts to configure a new user account with development tools and custom configurations.

## Features

### Installed Tools
- **zsh** with **Oh-My-Zsh** and popular plugins:
  - zsh-autosuggestions
  - zsh-syntax-highlighting
- **tmux** with TPM (Tmux Plugin Manager)
- **Node.js** via **nvm** (Node Version Manager)
- **Python** via **pyenv**
- **fzf** (fuzzy finder)
- **SSH keys** (ed25519)

### Restored Configurations
- `.zshrc`
- `.oh-my-zsh/custom/`
- `.tmux.conf`
- `.tmux/` directory
- `.gitconfig`
- `.vimrc` (if exists)
- `.bashrc` (if exists)
- SSH config

## Quick Start

### Step 1: Backup Current Configurations

On your current/source account, backup your dotfiles:

```bash
cd /home/jday/ansible/account_setup
./backup_dotfiles.sh
```

This will create a `dotfiles/` directory with all your configurations.

### Step 2: Transfer to New Account

Copy the entire `account_setup` directory to the new user account:

```bash
# From source machine
scp -r /home/jday/ansible/account_setup newuser@newhost:~/

# Or use rsync
rsync -avz /home/jday/ansible/account_setup/ newuser@newhost:~/account_setup/
```

### Step 3: Run Setup Script

On the new user account:

```bash
cd ~/account_setup
./setup_user_account.sh
```

The script will:
1. Install system packages
2. Configure zsh and Oh-My-Zsh
3. Set up tmux
4. Install nvm and Node.js
5. Install pyenv and Python
6. Generate SSH keys
7. Install additional utilities (fzf)
8. Create common directories

### Step 4: Post-Setup

1. **Log out and log back in** for shell changes to take effect
2. **Install tmux plugins**: Open tmux and press `prefix + I` (default: `Ctrl+b` then `Shift+I`)
3. **Add SSH key to remote servers**: Copy `~/.ssh/id_ed25519.pub` to target servers

## Script Details

### `backup_dotfiles.sh`

Backs up your current user's configuration files to the `dotfiles/` directory.

**What it backs up:**
- `.zshrc`
- `.oh-my-zsh/custom/`
- `.tmux.conf`
- `.tmux/` (excluding plugins)
- `.gitconfig`
- `.vimrc`
- `.bashrc`
- `.ssh/config` (not keys!)

**Usage:**
```bash
./backup_dotfiles.sh
```

### `setup_user_account.sh`

Idempotent setup script that can be run multiple times safely. It checks for existing installations before attempting to install or configure anything.

**Features:**
- ✅ Idempotent (safe to run multiple times)
- ✅ Interactive prompts for Git and SSH configuration
- ✅ Color-coded output
- ✅ Skips already installed components
- ✅ Creates sensible default directories

**Usage:**
```bash
./setup_user_account.sh
```

**Sudo Required:**
The script will prompt for sudo password to:
- Install system packages
- Change default shell to zsh

## Directory Structure

```
account_setup/
├── README.md                    # This file
├── backup_dotfiles.sh          # Backup script
├── setup_user_account.sh       # Setup script
└── dotfiles/                    # Configuration files (created by backup script)
    ├── .zshrc
    ├── .tmux.conf
    ├── .gitconfig
    ├── .oh-my-zsh/
    │   └── custom/
    ├── .tmux/
    ├── .ssh/
    │   └── config
    └── MANIFEST.txt            # Backup manifest
```

## Additional Customizations

### Suggested Improvements

1. **Vim/Neovim Configuration**
   - Install vim-plug or packer.nvim for plugin management
   - Add a comprehensive `.vimrc` or `init.vim`

2. **Git Aliases** (add to `.gitconfig` or `.zshrc`):
   ```bash
   alias gs='git status'
   alias ga='git add'
   alias gc='git commit'
   alias gp='git push'
   alias gl='git log --oneline --graph'
   alias gco='git checkout'
   ```

3. **Docker**
   ```bash
   sudo apt-get install docker.io docker-compose
   sudo usermod -aG docker $USER
   ```

4. **Additional zsh plugins** (add to `.zshrc`):
   ```bash
   plugins=(
       git
       docker
       kubectl
       terraform
       ansible
       python
       node
       npm
       zsh-autosuggestions
       zsh-syntax-highlighting
   )
   ```

5. **Starship Prompt** (modern cross-shell prompt):
   ```bash
   curl -sS https://starship.rs/install.sh | sh
   echo 'eval "$(starship init zsh)"' >> ~/.zshrc
   ```

6. **Bat** (better cat):
   ```bash
   sudo apt install bat
   alias cat='batcat'  # On Ubuntu/Debian
   ```

7. **Eza** (modern ls replacement):
   ```bash
   cargo install eza
   alias ls='eza'
   alias ll='eza -l'
   alias la='eza -la'
   ```

8. **Ripgrep** (fast grep alternative):
   ```bash
   sudo apt install ripgrep
   ```

9. **Delta** (better git diff):
   ```bash
   cargo install git-delta
   # Add to .gitconfig:
   [core]
       pager = delta
   ```

10. **Environment Variables** (add to `.zshrc`):
    ```bash
    export EDITOR=vim
    export VISUAL=vim
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    ```

### Tmux Suggested Plugins

Add to `.tmux.conf`:
```bash
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'

# Initialize TMUX plugin manager (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
```

### Ansible Vault Password File

For Ansible users, you may want to set up a vault password file:
```bash
# Store encrypted
echo "your_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass

# Reference in ansible.cfg
[defaults]
vault_password_file = ~/.vault_pass
```

## Troubleshooting

### Zsh not set as default shell
```bash
chsh -s $(which zsh)
# Then log out and log back in
```

### NVM not found after install
```bash
# Add to your shell rc file:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Pyenv not found
```bash
# Add to your shell rc file:
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

### Oh-My-Zsh installation hangs
The script uses `--unattended` flag. If it still hangs, you may need to kill any existing zsh processes:
```bash
pkill -9 zsh
```

### Tmux plugins not loading
1. Make sure TPM is installed: `~/.tmux/plugins/tpm`
2. Press `prefix + I` (capital i) to install plugins
3. Reload tmux config: `tmux source ~/.tmux.conf`

## Security Notes

1. **SSH Keys**: The backup script does NOT backup private SSH keys (by design)
2. **Vault Passwords**: Never commit vault passwords or sensitive credentials
3. **Git Credentials**: Consider using SSH keys for Git instead of HTTPS passwords
4. **File Permissions**: The scripts automatically set appropriate permissions (700 for .ssh, 600 for keys)

## Contributing

Feel free to modify these scripts to suit your needs. Some ideas:
- Add more development tools (Rust, Go, Ruby, etc.)
- Add IDE/editor configurations (VSCode, IntelliJ)
- Add containerization tools (Docker, Podman)
- Add cloud CLI tools (AWS CLI, gcloud, Azure CLI)

## License

These scripts are provided as-is for personal use. Modify as needed for your environment.
