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

# Sudo helper. Self Service+ / TouchID-gated sudo on locked-down work
# Macs doesn't cache credentials between calls, and brew shells out to
# `sudo /usr/sbin/installer` for .pkg casks (google-drive, microsoft-
# office, etc.) with no TTY available. To get past this we:
#
#   1. Stash the user's sudo password in their login Keychain (one
#      time; reuses the entry on subsequent runs).
#   2. Write a small askpass helper that prints the Keychain entry to
#      stdout.
#   3. Export SUDO_ASKPASS so brew adds `-A` to its sudo invocations,
#      and pass the same helper to ansible-playbook via
#      --become-password-file so Ansible's own become uses it too.
#
# To rotate the stored password (e.g. after a work password change):
#   security delete-generic-password -a "$USER" -s ansible-macos-workstation-sudo
KEYCHAIN_SERVICE="ansible-macos-workstation-sudo"
ASKPASS_DIR="${HOME}/.cache/ansible-macos-workstation"
ASKPASS_HELPER="${ASKPASS_DIR}/askpass.sh"

mkdir -p "${ASKPASS_DIR}"
cat >"${ASKPASS_HELPER}" <<EOF
#!/usr/bin/env bash
exec /usr/bin/security find-generic-password -a "\${USER}" -s "${KEYCHAIN_SERVICE}" -w 2>/dev/null
EOF
chmod 700 "${ASKPASS_HELPER}"

# Prompt for and store the sudo password, validating against `sudo -S`
# before we ship it off to ansible-playbook. Catching a bad password
# here saves ~1-2 minutes of wasted play time and avoids the cryptic
# "Duplicate become password prompt encountered" failure mode.
prompt_and_store_sudo_pw() {
  echo "Storing your sudo password in your login Keychain (service: ${KEYCHAIN_SERVICE})."
  read -rsp "Sudo password: " _SUDO_PW
  echo
  /usr/bin/security delete-generic-password \
    -a "${USER}" -s "${KEYCHAIN_SERVICE}" >/dev/null 2>&1 || true
  /usr/bin/security add-generic-password \
    -a "${USER}" \
    -s "${KEYCHAIN_SERVICE}" \
    -w "${_SUDO_PW}"
  unset _SUDO_PW
}

validate_sudo_pw() {
  # Drop any cached sudo timestamp first so we test the actual password,
  # not a passive cache hit. Pipe the password to `sudo -S -k -v`.
  /usr/bin/sudo -k 2>/dev/null || true
  "${ASKPASS_HELPER}" | /usr/bin/sudo -S -p '' -v >/dev/null 2>&1
}

if ! /usr/bin/security find-generic-password \
       -a "${USER}" -s "${KEYCHAIN_SERVICE}" -w >/dev/null 2>&1; then
  prompt_and_store_sudo_pw
fi

# Validate; on failure, rotate and validate once more, then bail.
if ! validate_sudo_pw; then
  echo "Stored sudo password failed validation (likely typo or rotated)."
  prompt_and_store_sudo_pw
  if ! validate_sudo_pw; then
    echo "Sudo authentication still failing. Aborting."
    echo "Make sure Self Service+ has granted you sudo, then re-run."
    exit 1
  fi
fi

export SUDO_ASKPASS="${ASKPASS_HELPER}"

# Run the playbook against the local host. The askpass helper supplies
# the password to both Ansible's become and brew's internal sudo calls.
until ansible-playbook --extra-vars "local_user=${USER}" \
  --become-password-file "${ASKPASS_HELPER}" \
  setup_workstation.yml; do
  echo "Ansible run disrupted, retrying in 10 seconds..."
  sleep 10
done
