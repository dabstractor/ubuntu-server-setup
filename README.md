# Server Setup

Automated server configuration script for Ubuntu.

## Testing with Multipass

### Launch VM
```bash
multipass launch --name test-server --cpus 2 --memory 2G --disk 10G
```

### Transfer files
```bash
multipass transfer setup-server.sh test-server:/home/ubuntu/
multipass transfer starship.toml test-server:/home/ubuntu/
```

### Run setup
```bash
multipass shell test-server
chmod +x setup-server.sh
./setup-server.sh
```

### Cleanup
```bash
multipass delete test-server
multipass purge
```

## What the script does

1. Configures sudo for session-based passwords
2. Prevents laptop from sleeping when lid closes
3. Installs zsh and sets as default shell
4. Installs Docker and Git
5. Installs Starship prompt with custom theme
6. Sets up Znap package manager with plugins
7. Installs lazygit, lazydocker, delta, meld
8. Configures git diff/merge tools
9. Installs neovim with custom config
10. Sets up SSH key authentication from GitHub
11. Disables SSH password authentication
