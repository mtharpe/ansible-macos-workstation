#!/usr/bin/env bash
set -euo pipefail

# Change to script directory (repo root)
cd "$(dirname "$0")"

# Ensure Xcode CLT is present (required by Homebrew)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (a GUI prompt will appear)..."
  xcode-select --install || true
fi

# Ensure Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add brew to PATH for this run (Apple Silicon default)
BREW_PREFIX="$(/opt/homebrew/bin/brew --prefix 2>/dev/null || /usr/local/bin/brew --prefix 2>/dev/null || true)"
if [ -n "${BREW_PREFIX}" ]; then
  export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"
fi

# Ensure Ansible is installed
if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "Installing Ansible..."
  brew install ansible
fi

# Install required Ansible collections
ansible-galaxy collection install -r requirements.yml

# Run the playbook against the local host. macOS asks for the user's
# login password the first time `become: true` runs (e.g. adding fish to
# /etc/shells, changing the user's shell).
until ansible-playbook --extra-vars "local_user=${USER}" \
  --ask-become-pass setup_workstation.yml; do
  echo "Ansible run disrupted, retrying in 10 seconds..."
  sleep 10
done
