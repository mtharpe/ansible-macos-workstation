# Changelog

## Unreleased
- Restructure repository to match `ansible-fedora-workstation-base`,
  `ansible-ubuntu-workstation-base`, and `ansible-manjaro-workstation-base`
  layout (`setup_workstation.yml`, `run.sh`, `Makefile`, `.ansible-lint`,
  `.yamllint`, `.circleci/`, `molecule/{default,docker}`, top-level
  `templates/`, `handlers/`, `meta/`).
- Consolidate per-tool roles (`gh_cli`, `ghostty`, `git_config`, `homebrew`,
  `htop`, `macos_settings`, `shell`, `ssh`, `starship`, `tmux`) into three
  roles: `common`, `third-party`, `macos`, gated by `install_*` flags in
  `vars/vars.yml`. The old `lxc` role and its config template were dropped
  (LXD/LXC client is no longer in use).
- Make `brew update` non-counting toward `changed` so the play is fully
  idempotent: split it from the install task and mark `changed_when: false`.
- Add Dock, menu-bar, keyboard, screenshot, trackpad, and Finder defaults
  reflecting the current workstation's state.
- Add `dockutil`-based Dock layout management.
- Add CircleCI workflow with `ansible-lint`, `yamllint`,
  `ansible-playbook --syntax-check`, `molecule syntax`, and `shellcheck`.
