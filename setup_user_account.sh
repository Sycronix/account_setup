#!/usr/bin/env bash

#############################################################################
# User Account Setup Script
# Purpose: Idempotent script to configure a new user account with:
#   - zsh, oh-my-zsh, tmux
#   - node, nvm, pyenv
#   - SSH keys (ed25519)
#   - Custom configurations
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/dotfiles"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should NOT be run as root. Run as the target user."
   exit 1
fi

#############################################################################
# System Package Installation
#############################################################################

install_system_packages() {
    log_info "Installing system packages (zsh, tmux, git, curl, build-essential)..."

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf check-update || true"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
        UPDATE_CMD="sudo yum check-update || true"
    else
        log_error "No supported package manager found (apt/dnf/yum)"
        exit 1
    fi

    # Update package list
    log_info "Updating package lists..."
    $UPDATE_CMD

    # Install packages
    local packages="zsh tmux git curl wget build-essential"

    if [[ "$PKG_MANAGER" == "apt" ]]; then
        packages="zsh tmux git curl wget build-essential libssl-dev zlib1g-dev \
                  libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev \
                  xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev"
    elif [[ "$PKG_MANAGER" == "dnf" ]] || [[ "$PKG_MANAGER" == "yum" ]]; then
        packages="zsh tmux git curl wget gcc gcc-c++ make openssl-devel \
                  bzip2-devel libffi-devel zlib-devel readline-devel \
                  sqlite-devel xz-devel"
    fi

    for package in $packages; do
        if ! dpkg -l | grep -q "^ii  $package" 2>/dev/null && \
           ! rpm -q $package &>/dev/null; then
            log_info "Installing $package..."
            $INSTALL_CMD $package
        else
            log_success "$package already installed"
        fi
    done

    log_success "System packages installed"
}

#############################################################################
# Zsh & Oh-My-Zsh Setup
#############################################################################

setup_zsh() {
    log_info "Setting up Zsh and Oh-My-Zsh..."

    # Set zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        log_info "Setting zsh as default shell..."
        sudo chsh -s "$(which zsh)" "$USER"
        log_success "Zsh set as default shell (re-login to take effect)"
    else
        log_success "Zsh already set as default shell"
    fi

    # Install Oh-My-Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh-My-Zsh installed"
    else
        log_success "Oh-My-Zsh already installed"
    fi

    # Install popular zsh plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_success "zsh-autosuggestions already installed"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_success "zsh-syntax-highlighting already installed"
    fi

    # Restore .zshrc if exists
    if [[ -f "$CONFIG_DIR/.zshrc" ]]; then
        log_info "Restoring .zshrc..."
        cp "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
        log_success ".zshrc restored"
    else
        log_warning "No .zshrc found in $CONFIG_DIR"
    fi

    # Restore oh-my-zsh custom directory if exists
    if [[ -d "$CONFIG_DIR/.oh-my-zsh/custom" ]]; then
        log_info "Restoring oh-my-zsh custom configurations..."
        cp -r "$CONFIG_DIR/.oh-my-zsh/custom/"* "$ZSH_CUSTOM/"
        log_success "Oh-My-Zsh custom configs restored"
    fi
}

#############################################################################
# Tmux Setup
#############################################################################

setup_tmux() {
    log_info "Setting up Tmux..."

    # Restore .tmux.conf
    if [[ -f "$CONFIG_DIR/.tmux.conf" ]]; then
        log_info "Restoring .tmux.conf..."
        cp "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"
        log_success ".tmux.conf restored"
    else
        log_warning "No .tmux.conf found in $CONFIG_DIR"
    fi

    # Restore .tmux directory
    if [[ -d "$CONFIG_DIR/.tmux" ]]; then
        log_info "Restoring .tmux directory..."
        cp -r "$CONFIG_DIR/.tmux" "$HOME/"
        log_success ".tmux directory restored"
    fi

    # Install TPM (Tmux Plugin Manager)
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_info "Installing Tmux Plugin Manager (TPM)..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        log_success "TPM installed (run 'prefix + I' in tmux to install plugins)"
    else
        log_success "TPM already installed"
    fi
}

#############################################################################
# NVM & Node.js Setup
#############################################################################

setup_nvm_node() {
    log_info "Setting up NVM and Node.js..."

    # Install NVM
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_info "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

        # Source NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        log_success "NVM installed"
    else
        log_success "NVM already installed"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Install latest LTS Node.js
    if ! command -v node &> /dev/null; then
        log_info "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        nvm alias default 'lts/*'
        log_success "Node.js LTS installed"
    else
        log_success "Node.js already installed: $(node --version)"
    fi
}

#############################################################################
# Pyenv Setup
#############################################################################

setup_pyenv() {
    log_info "Setting up pyenv..."

    # Install pyenv
    if [[ ! -d "$HOME/.pyenv" ]]; then
        log_info "Installing pyenv..."
        curl https://pyenv.run | bash

        # Add to PATH for this session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"

        log_success "pyenv installed"
    else
        log_success "pyenv already installed"
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
    fi

    # Install latest Python 3
    if ! pyenv versions | grep -q "3\."; then
        log_info "Installing latest Python 3..."
        LATEST_PYTHON=$(pyenv install --list | grep -E "^\s*3\.[0-9]+\.[0-9]+$" | tail -1 | tr -d '[:space:]')
        log_info "Installing Python $LATEST_PYTHON..."
        pyenv install "$LATEST_PYTHON"
        pyenv global "$LATEST_PYTHON"
        log_success "Python $LATEST_PYTHON installed and set as global"
    else
        log_success "Python 3 already installed: $(pyenv version)"
    fi
}

#############################################################################
# SSH Key Setup
#############################################################################

setup_ssh_keys() {
    log_info "Setting up SSH keys..."

    # Create .ssh directory if it doesn't exist
    if [[ ! -d "$HOME/.ssh" ]]; then
        log_info "Creating .ssh directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        log_success ".ssh directory created"
    else
        log_success ".ssh directory exists"
        chmod 700 "$HOME/.ssh"
    fi

    # Generate ed25519 key if it doesn't exist
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_info "Generating ed25519 SSH key..."
        read -p "Enter email for SSH key (or press enter to skip): " ssh_email
        if [[ -n "$ssh_email" ]]; then
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519" -N ""
        else
            ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -N ""
        fi
        chmod 600 "$HOME/.ssh/id_ed25519"
        chmod 644 "$HOME/.ssh/id_ed25519.pub"
        log_success "SSH key generated"
        echo ""
        log_info "Your public key:"
        cat "$HOME/.ssh/id_ed25519.pub"
        echo ""
    else
        log_success "SSH key already exists"
        log_info "Public key location: $HOME/.ssh/id_ed25519.pub"
    fi

    # Create/update SSH config with sensible defaults
    if [[ ! -f "$HOME/.ssh/config" ]]; then
        log_info "Creating SSH config with sensible defaults..."
        cat > "$HOME/.ssh/config" << 'EOF'
# Global SSH settings
Host *
    AddKeysToAgent yes
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
EOF
        chmod 600 "$HOME/.ssh/config"
        log_success "SSH config created"
    else
        log_success "SSH config already exists"
    fi
}

#############################################################################
# Additional Utilities & Configurations
#############################################################################

setup_additional_tools() {
    log_info "Setting up additional tools and configurations..."

    # Install fzf (fuzzy finder)
    if [[ ! -d "$HOME/.fzf" ]]; then
        log_info "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --all
        log_success "fzf installed"
    else
        log_success "fzf already installed"
    fi

    # Create common directories
    local dirs=("$HOME/projects" "$HOME/bin" "$HOME/.local/bin")
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        fi
    done

    # Add ~/.local/bin to PATH if not already there
    if [[ ! -f "$HOME/.profile" ]] || ! grep -q ".local/bin" "$HOME/.profile"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
        log_success "Added ~/.local/bin to PATH in .profile"
    fi

    # Create .gitconfig with basic settings if it doesn't exist
    if [[ ! -f "$HOME/.gitconfig" ]]; then
        log_info "Creating basic .gitconfig..."
        read -p "Enter your Git name (or press enter to skip): " git_name
        read -p "Enter your Git email (or press enter to skip): " git_email

        if [[ -n "$git_name" ]] && [[ -n "$git_email" ]]; then
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            git config --global init.defaultBranch main
            git config --global pull.rebase false
            git config --global core.editor "vim"
            log_success "Git configured"
        fi
    else
        log_success "Git already configured"
    fi
}

#############################################################################
# Main Function
#############################################################################

main() {
    echo ""
    log_info "=========================================="
    log_info "User Account Setup Script"
    log_info "=========================================="
    echo ""

    # Check if config directory exists
    if [[ ! -d "$CONFIG_DIR" ]]; then
        log_warning "Config directory not found: $CONFIG_DIR"
        log_info "Creating config directory. You should populate it with your dotfiles."
        mkdir -p "$CONFIG_DIR"
    fi

    # Run setup functions
    install_system_packages
    echo ""

    setup_zsh
    echo ""

    setup_tmux
    echo ""

    setup_nvm_node
    echo ""

    setup_pyenv
    echo ""

    setup_ssh_keys
    echo ""

    setup_additional_tools
    echo ""

    log_success "=========================================="
    log_success "Setup Complete!"
    log_success "=========================================="
    echo ""
    log_info "Next steps:"
    log_info "1. Log out and log back in for shell changes to take effect"
    log_info "2. If using tmux, press 'prefix + I' to install tmux plugins"
    log_info "3. Add your SSH public key to remote servers: ~/.ssh/id_ed25519.pub"
    log_info "4. Review and customize your configurations in ~/"
    echo ""
}

# Run main function
main "$@"
