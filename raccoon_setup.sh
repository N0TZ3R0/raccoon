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
# This script checks if the user has all the required scan tools and installs
# them if the user accepts. It also asks for the ChatGPT API key and sets it
# globally. Finally, it creates a command for raccoon on the machine.
###############################################################################

# List of required scan tools
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

# Function to check if a tool is installed
check_tool() {
  if ! command -v $1 &> /dev/null; then
    echo "$1 is not installed."
    return 1
  else
    echo "$1 is already installed."
    return 0
  fi
}

# Function to install a tool
install_tool() {
  sudo apt-get install -y $1
}

# Function to load modules
load_modules() {
  for tool in "${REQUIRED_TOOLS[@]}"; do
    check_tool $tool
    if [ $? -eq 1 ]; then
      read -p "Do you want to install $tool? (y/n): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        install_tool $tool
      else
        echo "$tool will not be installed."
      fi
    fi
  done
}

# Run the module loader
load_modules

# Ask for ChatGPT API key
read -p "Enter your ChatGPT API key: " openai_api_key

# Set the API key and tools pile in the .env file
echo "OPENAI_API_KEY=$openai_api_key" > .env
echo "TOOLS_PILE=[\"${REQUIRED_TOOLS[@]}\"]" >> .env

# Install bundler and gems
echo "Installing bundler and gems..."
gem install bundler
bundle install

# Create a command for raccoon
echo "Creating raccoon command..."
sudo ln -s $(pwd)/bin/raccoon /usr/local/bin/raccoon
sudo chmod +x $(pwd)/bin/raccoon

# Add raccoon command to .bashrc or .zshrc
if [ -f "$HOME/.bashrc" ]; then
  echo "Adding raccoon command to .bashrc..."
  echo 'export PATH="$PATH:/usr/local/bin/raccoon"' >> $HOME/.bashrc
  source $HOME/.bashrc
elif [ -f "$HOME/.zshrc" ]; then
  echo "Adding raccoon command to .zshrc..."
  echo 'export PATH="$PATH:/usr/local/bin/raccoon"' >> $HOME/.zshrc
  source $HOME/.zshrc
else
  echo "No .bashrc or .zshrc file found. Please add 'export PATH=\"$PATH:/usr/local/bin/raccoon\"' to your shell configuration file manually."
fi

echo "Setup completed"
