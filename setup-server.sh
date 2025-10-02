#!/bin/bash

# Server Setup Script
# Sets up a server with zsh, docker, git, neovim, and various tools

set -e

echo "=== Server Setup Script ==="
echo

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Please run this script as a regular user with sudo privileges."
        exit 1
    fi
}

# Configure sudo to require password only once per session
configure_sudo() {
    echo "[1/15] Configuring sudo for session-based passwords..."

    # First, get sudo access and start a background refresh
    sudo -v

    # Keep sudo alive in background (update every 60s until script exits)
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_REFRESH_PID=$!

    # Configure permanent setting for future sessions
    echo "Defaults timestamp_timeout=-1" | sudo tee /etc/sudoers.d/session-sudo > /dev/null
    sudo chmod 440 /etc/sudoers.d/session-sudo

    echo "✓ Sudo configured (password valid for this session)"
    echo
}

# Configure laptop lid behavior (only for laptops)
configure_lid() {
    echo "[2/15] Configuring laptop lid behavior..."
    if [ -f /etc/systemd/logind.conf ]; then
        sudo sed -i 's/#HandleLidSwitch=.*/HandleLidSwitch=ignore/' /etc/systemd/logind.conf
        sudo sed -i 's/#HandleLidSwitchExternalPower=.*/HandleLidSwitchExternalPower=ignore/' /etc/systemd/logind.conf
        sudo systemctl restart systemd-logind || true
        echo "✓ Laptop lid configured to not suspend"
    else
        echo "⚠ systemd-logind not found, skipping"
    fi
    echo
}

# Update system
update_system() {
    echo "[3/15] Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo "✓ System updated"
    echo
}

# Install zsh
install_zsh() {
    echo "[4/15] Installing zsh..."
    if command -v zsh &> /dev/null; then
        echo "✓ zsh already installed"
    else
        sudo apt install -y zsh
        echo "✓ zsh installed"
    fi
    echo
}

# Set zsh as default shell
set_zsh_default() {
    echo "[5/15] Setting zsh as default shell..."
    current_shell=$(getent passwd "$(whoami)" | cut -d: -f7)
    if [ "$current_shell" = "$(which zsh)" ]; then
        echo "✓ zsh already set as default shell"
    else
        sudo chsh -s "$(which zsh)" "$(whoami)"
        echo "✓ zsh set as default shell"
    fi
    echo
}

# Install Docker
install_docker() {
    echo "[6/15] Installing Docker..."
    if command -v docker &> /dev/null; then
        echo "✓ Docker already installed"
        # Still ensure user is in docker group
        if ! groups "$(whoami)" | grep -q docker; then
            sudo usermod -aG docker "$(whoami)"
            echo "✓ Added user to docker group"
        fi
    else
        sudo apt install -y ca-certificates curl gnupg
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        sudo usermod -aG docker "$(whoami)"
        echo "✓ Docker installed"
    fi
    echo
}

# Install git
install_git() {
    echo "[7/15] Installing git..."
    if command -v git &> /dev/null; then
        echo "✓ git already installed"
    else
        sudo apt install -y git
        echo "✓ git installed"
    fi
    echo
}

# Install starship
install_starship() {
    echo "[8/15] Installing starship..."
    if command -v starship &> /dev/null; then
        echo "✓ starship already installed"
    else
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Always ensure config exists
    mkdir -p ~/.config
    if [ ! -f ~/.config/starship.toml ]; then
        starship preset no-empty-icons > ~/.config/starship.toml
        echo "✓ Starship config created"
    else
        echo "✓ Starship config already exists"
    fi
    echo
}

# Install Znap and plugins
install_znap() {
    echo "[9/15] Installing Znap and plugins..."
    
    if [ -d ~/.config/znap/src ]; then
        echo "✓ Znap already installed"
    else
        mkdir -p ~/.config/znap
        git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git ~/.config/znap/src
        echo "✓ Znap installed"
    fi
    
    # Initialize znap and install plugins (znap handles idempotency)
    zsh -c '
        source ~/.config/znap/src/znap.zsh
        znap source Aloxaf/fzf-tab
        znap source ael-code/zsh-colored-man-pages
        znap source jeffreytse/zsh-vi-mode
        znap source mafredri/zsh-async
        znap source momo-lab/zsh-abbrev-alias
        znap source robbyrussel/oh-my-zsh
        znap source rupa/z
        znap source sorin-ionescu/prezto
        znap source zsh-users/zsh-autosuggestions
        znap source zsh-users/zsh-completions
        znap source zsh-users/zsh-syntax-highlighting
    '
    echo "✓ Znap plugins configured"
    echo
}

# Install lazygit
install_lazygit() {
    echo "[10/15] Installing lazygit..."
    if command -v lazygit &> /dev/null; then
        echo "✓ lazygit already installed"
    else
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
        echo "✓ lazygit installed"
    fi
    echo
}

# Install lazydocker
install_lazydocker() {
    echo "[11/15] Installing lazydocker..."
    if command -v lazydocker &> /dev/null; then
        echo "✓ lazydocker already installed"
    else
        curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        echo "✓ lazydocker installed"
    fi
    echo
}

# Install delta
install_delta() {
    echo "[12/15] Installing delta..."
    if command -v delta &> /dev/null; then
        echo "✓ delta already installed"
    else
        DELTA_VERSION=$(curl -s "https://api.github.com/repos/dandavison/delta/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
        curl -Lo delta.deb "https://github.com/dandavison/delta/releases/latest/download/git-delta_${DELTA_VERSION}_amd64.deb"
        sudo dpkg -i delta.deb
        rm delta.deb
        echo "✓ delta installed"
    fi
    echo
}

# Install meld
install_meld() {
    echo "[13/15] Installing meld..."
    if command -v meld &> /dev/null; then
        echo "✓ meld already installed"
    else
        sudo apt install -y meld
        echo "✓ meld installed"
    fi
    echo
}

# Configure git diff and merge tools
configure_git_tools() {
    echo "[14/15] Configuring git diff and merge tools..."
    git config --global core.pager delta
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate true
    git config --global delta.light false
    git config --global merge.conflictstyle diff3
    git config --global diff.colorMoved default
    git config --global diff.tool meld
    git config --global merge.tool meld
    echo "✓ Git tools configured"
    echo
}

# Install neovim
install_neovim() {
    echo "[15/15] Installing neovim..."
    if command -v nvim &> /dev/null; then
        echo "✓ neovim already installed"
    else
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
        sudo apt update
        sudo apt install -y neovim
        echo "✓ neovim installed"
    fi
    
    # Clone neovim config if not exists
    if [ -d ~/.config/nvim/.git ]; then
        echo "✓ neovim config already exists"
    else
        mkdir -p ~/.config/nvim
        git clone https://github.com/dabstractor/nvim-config.git ~/.config/nvim
        echo "✓ neovim config cloned"
    fi
    echo
}

# Setup tab completion
setup_completions() {
    echo "Setting up tab completion..."
    # This will be handled by znap and zsh plugins
    echo "✓ Tab completion configured via zsh plugins"
    echo
}

# Configure SSH
configure_ssh() {
    echo "Configuring SSH..."
    
    # Get SSH keys from GitHub
    GITHUB_USER="${1:-dabstractor}"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    echo "Fetching SSH keys from GitHub..."
    curl -s "https://github.com/${GITHUB_USER}.keys" > /tmp/github_keys.txt
    
    # Check if key already exists in authorized_keys
    if [ -f ~/.ssh/authorized_keys ]; then
        while IFS= read -r key; do
            if ! grep -qF "$key" ~/.ssh/authorized_keys; then
                echo "$key" >> ~/.ssh/authorized_keys
                echo "✓ Added new key from GitHub"
            else
                echo "✓ Key already exists in authorized_keys"
            fi
        done < /tmp/github_keys.txt
    else
        cat /tmp/github_keys.txt > ~/.ssh/authorized_keys
        echo "✓ Created authorized_keys with GitHub keys"
    fi
    
    chmod 600 ~/.ssh/authorized_keys
    rm /tmp/github_keys.txt
    
    # Configure SSH to only allow key-based authentication
    echo "Configuring SSH daemon..."
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd || sudo systemctl restart ssh
    echo "✓ SSH configured for key-only authentication"
    echo
}

# Create .zshrc
create_zshrc() {
    echo "Creating .zshrc configuration..."
    
    # Backup existing .zshrc if it exists and doesn't have our marker
    MARKER="# Znap initialization"
    if [ -f ~/.zshrc ] && ! grep -q "$MARKER" ~/.zshrc; then
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
        echo "✓ Backed up existing .zshrc"
    fi
    
    # Only create if it doesn't already have our configuration
    if [ -f ~/.zshrc ] && grep -q "$MARKER" ~/.zshrc; then
        echo "✓ .zshrc already configured"
        return
    fi
    
    cat > ~/.zshrc << 'ZSHRC_END'
# Znap initialization
source ~/.config/znap/src/znap.zsh

# Load plugins
znap source Aloxaf/fzf-tab
znap source ael-code/zsh-colored-man-pages
znap source jeffreytse/zsh-vi-mode
znap source mafredri/zsh-async
znap source momo-lab/zsh-abbrev-alias
znap source robbyrussel/oh-my-zsh
znap source rupa/z
znap source sorin-ionescu/prezto
znap source zsh-users/zsh-autosuggestions
znap source zsh-users/zsh-completions
znap source zsh-users/zsh-syntax-highlighting

# Starship prompt
eval "$(starship init zsh)"

# Completion settings
autoload -Uz compinit
compinit

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Aliases
# Editor aliases
alias vim='nvim'
alias vi='nvim'
alias nv='nvim'

# ls aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Docker aliases
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcl='docker compose logs'
alias dcf='docker compose logs -f'
alias dcs='docker compose stop'
alias de='docker exec -it'

# TUI tool aliases
alias lg='lazygit'
alias ld='lazydocker'

# Git aliases
alias gpc='git add -A && git commit -n -m "progress commit" && git push'
alias pgc='git add -A && git commit -n -m "progress commit"'

# Other utilities
alias s='sudo -E'
alias g='grep -i'

ZSHRC_END
    echo "✓ .zshrc created"
    echo
}

# Main execution
main() {
    check_root
    
    # Ask for GitHub username for SSH key fetching
    read -p "Enter your GitHub username (default: dabstractor): " github_user
    github_user=${github_user:-dabstractor}
    
    configure_sudo
    configure_lid
    update_system
    install_zsh
    install_git
    install_docker
    install_starship
    install_znap
    install_lazygit
    install_lazydocker
    install_delta
    install_meld
    configure_git_tools
    install_neovim
    setup_completions
    configure_ssh "$github_user"
    create_zshrc
    set_zsh_default
    
    echo "=== Setup Complete! ==="
    echo
    echo "Important notes:"
    echo "1. You may need to log out and log back in for group changes (Docker) to take effect"
    echo "2. Your default shell has been changed to zsh - restart your terminal or run 'zsh'"
    echo "3. SSH has been configured to only allow key-based authentication"
    echo "4. Sudo password will be required only once per session"
    echo "5. Run 'source ~/.zshrc' to load your new shell configuration"
    echo

    # Kill the sudo refresh background process
    [ -n "$SUDO_REFRESH_PID" ] && kill "$SUDO_REFRESH_PID" 2>/dev/null
}

main "$@"
