#!/bin/bash
###############################################################################
#                               R a c c o o n                                 #
###############################################################################
#  Copyright (C) 2024 0xZero
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; version 2
#  of the License only.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to
#  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Contact Information:
#     0xZero (notzero@proton.me)
#     https://Not.Zero/
###############################################################################

set -e

VERBOSE=false
DRY_RUN=false
LOG_FILE="raccoon_setup.log"
REQUIRED_RUBY_VERSION="3.0.0"

REQUIRED_TOOLS=(
  nmap
  nikto
  dnsrecon
  wafw00f
  sublist3r
  theHarvester
  smbmap
  enum4linux
  dirb
  whatweb
  smtp-user-enum
)

log() {
    echo "$(date): $1" >> "$LOG_FILE"
    $VERBOSE && echo "$1"
}

error() {
    echo "ERROR: $1" >&2
    log "ERROR: $1"
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_system_requirements() {
    log "Checking system requirements..."
    # Example: Check for at least 1GB of free disk space
    free_space=$(df -k . | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 1048576 ]; then
        error "Not enough free disk space. At least 1GB required."
    fi
}

check_network_connectivity() {
    log "Checking network connectivity..."
    if ! ping -c 1 google.com &> /dev/null; then
        error "No internet connection available."
    fi
}

backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak"
        log "Backed up $1 to $1.bak"
    fi
}

check_ruby_version() {
    log "Checking Ruby version..."
    if command_exists rbenv; then
        log "rbenv detected."
        RUBY_VERSION=$(rbenv version | cut -d ' ' -f 1)
        RUBY_MANAGER="rbenv"
    elif command_exists rvm; then
        log "RVM detected."
        RUBY_VERSION=$(rvm current)
        RUBY_MANAGER="rvm"
    else
        log "No Ruby version manager detected. It's recommended to use one for better Ruby management."
        RUBY_VERSION=$(ruby -v | cut -d ' ' -f 2)
        RUBY_MANAGER="system"
    fi

    log "Current Ruby version: $RUBY_VERSION"

    if [ "$(printf '%s\n' "$REQUIRED_RUBY_VERSION" "$RUBY_VERSION" | sort -V | head -n1)" != "$REQUIRED_RUBY_VERSION" ]; then
        log "Ruby version $REQUIRED_RUBY_VERSION or higher is required."
        if [ "$RUBY_MANAGER" = "rbenv" ]; then
            log "Installing Ruby $REQUIRED_RUBY_VERSION with rbenv..."
            $DRY_RUN || rbenv install $REQUIRED_RUBY_VERSION
            $DRY_RUN || rbenv local $REQUIRED_RUBY_VERSION
        elif [ "$RUBY_MANAGER" = "rvm" ]; then
            log "Installing Ruby $REQUIRED_RUBY_VERSION with RVM..."
            $DRY_RUN || rvm install $REQUIRED_RUBY_VERSION
            $DRY_RUN || rvm use $REQUIRED_RUBY_VERSION
        else
            error "Please install Ruby $REQUIRED_RUBY_VERSION manually."
        fi
    fi
}

install_bundler() {
    if ! command_exists bundler; then
        log "Installing bundler..."
        $DRY_RUN || gem install bundler
    else
        log "Bundler is already installed."
    fi
}

install_gems() {
    log "Installing gems..."
    $DRY_RUN || bundle install --path vendor/bundle
}

check_tool() {
    if ! command_exists $1; then
        log "$1 is not installed."
        return 1
    else
        log "$1 is already installed."
        return 0
    fi
}

install_tool() {
    log "Installing $1..."
    $DRY_RUN || sudo apt-get install -y $1
}

load_modules() {
    for tool in "${REQUIRED_TOOLS[@]}"; do
        check_tool $tool
        if [ $? -eq 1 ]; then
            read -p "Do you want to install $tool? (y/n): " answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                install_tool $tool
            else
                log "$tool will not be installed."
            fi
        fi
    done
}

setup_env_file() {
    log "Setting up .env file..."
    read -p "Enter your ChatGPT API key: " openai_api_key
    $DRY_RUN || echo "OPENAI_API_KEY=$openai_api_key" > .env
    $DRY_RUN || echo "TOOLS_PILE=[\"${REQUIRED_TOOLS[@]}\"]" >> .env
}

create_raccoon_command() {
    log "Creating raccoon command..."
    $DRY_RUN || sudo ln -sf $(pwd)/bin/raccoon /usr/local/bin/raccoon
    $DRY_RUN || sudo chmod +x $(pwd)/bin/raccoon
}

update_shell_config() {
    local shell_config
    if [ -f "$HOME/.zshrc" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_config="$HOME/.bashrc"
    else
        log "No .zshrc or .bashrc file found. Please add the following line to your shell configuration file manually:"
        log 'export PATH="$PATH:/usr/local/bin/raccoon"'
        return
    fi

    log "Updating $shell_config..."
    backup_file "$shell_config"
    if ! grep -q 'export PATH="$PATH:/usr/local/bin/raccoon"' "$shell_config"; then
        $DRY_RUN || echo 'export PATH="$PATH:/usr/local/bin/raccoon"' >> "$shell_config"
        log "Added raccoon to PATH in $shell_config"
    else
        log "raccoon already in PATH in $shell_config"
    fi
    $DRY_RUN || source "$shell_config"
}

check_for_updates() {
    log "Checking for Raccoon updates..."
    # Implement update checking logic here
    # For example, you could compare the local version with the latest release on GitHub
}

uninstall() {
    log "Uninstalling Raccoon..."
    # Implement uninstallation logic here
    # This should undo all the changes made by the installer
}

show_help() {
    echo "Usage: $0 [-v] [-d] [-u] [-h]"
    echo "  -v: Verbose mode"
    echo "  -d: Dry run (show what would be done without making changes)"
    echo "  -u: Uninstall Raccoon"
    echo "  -h: Show this help message"
}

main() {
    while getopts ":vduh" opt; do
        case ${opt} in
            v ) VERBOSE=true ;;
            d ) DRY_RUN=true ;;
            u ) uninstall; exit 0 ;;
            h ) show_help; exit 0 ;;
            \? ) show_help; exit 1 ;;
        esac
    done

    log "Starting Raccoon setup..."

    check_system_requirements
    check_network_connectivity

    if $DRY_RUN; then
        log "Dry run mode. No changes will be made."
    fi

    check_ruby_version
    install_bundler
    install_gems
    load_modules
    setup_env_file
    create_raccoon_command
    update_shell_config
    check_for_updates

    log "Raccoon setup completed successfully!"
}

main "$@"
