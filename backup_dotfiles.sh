#!/usr/bin/env bash

#############################################################################
# Dotfiles Backup Script
# Purpose: Export current user's configuration files to the dotfiles directory
#          so they can be restored on a new user account
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
DOTFILES_DIR="${SCRIPT_DIR}/dotfiles"

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

# Create dotfiles directory
mkdir -p "$DOTFILES_DIR"

log_info "=========================================="
log_info "Backing up dotfiles to: $DOTFILES_DIR"
log_info "=========================================="
echo ""

# Backup .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    log_info "Backing up .zshrc..."
    cp "$HOME/.zshrc" "$DOTFILES_DIR/.zshrc"
    log_success ".zshrc backed up"
else
    log_warning ".zshrc not found"
fi

# Backup oh-my-zsh custom directory
if [[ -d "$HOME/.oh-my-zsh/custom" ]]; then
    log_info "Backing up oh-my-zsh custom configurations..."
    mkdir -p "$DOTFILES_DIR/.oh-my-zsh"
    cp -r "$HOME/.oh-my-zsh/custom" "$DOTFILES_DIR/.oh-my-zsh/"
    log_success "oh-my-zsh custom configs backed up"
else
    log_warning "oh-my-zsh custom directory not found"
fi

# Backup .tmux.conf
if [[ -f "$HOME/.tmux.conf" ]]; then
    log_info "Backing up .tmux.conf..."
    cp "$HOME/.tmux.conf" "$DOTFILES_DIR/.tmux.conf"
    log_success ".tmux.conf backed up"
else
    log_warning ".tmux.conf not found"
fi

# Backup .tmux directory (excluding plugins - they should be reinstalled)
if [[ -d "$HOME/.tmux" ]]; then
    log_info "Backing up .tmux directory..."
    mkdir -p "$DOTFILES_DIR/.tmux"
    # Copy everything except plugins directory
    rsync -av --exclude='plugins/' "$HOME/.tmux/" "$DOTFILES_DIR/.tmux/" 2>/dev/null || \
        cp -r "$HOME/.tmux/"* "$DOTFILES_DIR/.tmux/" 2>/dev/null || true
    log_success ".tmux directory backed up"
fi

# Backup .gitconfig
if [[ -f "$HOME/.gitconfig" ]]; then
    log_info "Backing up .gitconfig..."
    cp "$HOME/.gitconfig" "$DOTFILES_DIR/.gitconfig"
    log_success ".gitconfig backed up"
fi

# Backup .vimrc if exists
if [[ -f "$HOME/.vimrc" ]]; then
    log_info "Backing up .vimrc..."
    cp "$HOME/.vimrc" "$DOTFILES_DIR/.vimrc"
    log_success ".vimrc backed up"
fi

# Backup .bashrc if exists
if [[ -f "$HOME/.bashrc" ]]; then
    log_info "Backing up .bashrc..."
    cp "$HOME/.bashrc" "$DOTFILES_DIR/.bashrc"
    log_success ".bashrc backed up"
fi

# Backup SSH config (but not keys!)
if [[ -f "$HOME/.ssh/config" ]]; then
    log_info "Backing up SSH config..."
    mkdir -p "$DOTFILES_DIR/.ssh"
    cp "$HOME/.ssh/config" "$DOTFILES_DIR/.ssh/config"
    log_success "SSH config backed up"
fi

# Create a manifest file
log_info "Creating backup manifest..."
cat > "$DOTFILES_DIR/MANIFEST.txt" << EOF
Dotfiles Backup Manifest
========================
Backup Date: $(date)
Backup User: $USER
Backup Host: $(hostname)

Files backed up:
EOF

find "$DOTFILES_DIR" -type f -not -name "MANIFEST.txt" | while read file; do
    echo "  - ${file#$DOTFILES_DIR/}" >> "$DOTFILES_DIR/MANIFEST.txt"
done

log_success "Manifest created"
echo ""
log_success "=========================================="
log_success "Backup Complete!"
log_success "=========================================="
log_info "Dotfiles backed up to: $DOTFILES_DIR"
log_info "You can now run setup_user_account.sh on a new user account"
echo ""
