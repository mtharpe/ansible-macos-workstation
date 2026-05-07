[![CircleCI](https://circleci.com/gh/mtharpe/ansible-macos-workstation/tree/main.svg?style=svg)](https://circleci.com/gh/mtharpe/ansible-macos-workstation/tree/main)

# macOS Workstation

Ansible playbook and role collection that automates the setup of a **macOS** workstation for development and daily use.

## What this does

Configures a macOS workstation with:

- **Common packages** — Homebrew taps, formulae, and developer-tooling casks (`roles/common`)
- **Third-party apps** — 1Password, Chrome, Slack, VS Code, Cursor, Claude, Zoom, Pixelmator Pro, Inkscape, etc., gated by `install_*` flags (`roles/third-party`)
- **macOS settings** — sensible `defaults`, dark mode, Finder, Dock layout (via `dockutil`), menu-bar clock, keyboard repeat, trackpad, screenshots (`roles/macos`)
- **Shell setup** — fish + Starship + tmux (TPM), with FiraCode/JetBrains/Hack/Meslo Nerd Fonts
- **Dotfiles** — fish config, tmux config, ghostty config, htop config, gh config, ssh config (1Password agent), git config (1Password SSH signing)

## Requirements

- macOS 14+ (Apple Silicon or Intel)
- A user account with admin rights
- Internet access for package installs

## Quick start

1. Clone the repository:

   ```sh
   git clone https://github.com/mtharpe/ansible-macos-workstation.git
   cd ansible-macos-workstation
   ```

2. Edit `vars/vars.yml` to set your `local_user`, the Dock layout, and toggle the `install_*` flags.

3. Run the bootstrap script (installs Xcode CLT + Homebrew + Ansible if missing, then applies the playbook):

   ```sh
   ./run.sh
   ```

   Or invoke ansible directly once Homebrew + Ansible are present:

   ```sh
   brew install ansible
   ansible-galaxy collection install -r requirements.yml
   ansible-playbook --extra-vars "local_user=$USER" --ask-become-pass setup_workstation.yml
   ```

## Feature flags

All toggles live in `vars/vars.yml`. The most useful ones:

| Flag | Default | What it controls |
|------|---------|------------------|
| `install_1password` | `true` | 1Password (also provides Git SSH signing + ssh-agent) |
| `install_chrome` | `true` | Google Chrome |
| `install_claude` | `true` | Claude Desktop |
| `install_cursor` | `true` | Cursor (AI editor) |
| `install_vscode` | `true` | Visual Studio Code |
| `install_slack` | `true` | Slack |
| `install_zoom` | `true` | Zoom |
| `install_orbstack` | `true` | OrbStack (Linux + Docker for macOS) |
| `install_google_drive` | `true` | Google Drive |
| `install_pixelmator_pro` | `true` | Pixelmator Pro |
| `install_inkscape` | `true` | Inkscape |
| `install_bambu_studio` | `true` | Bambu Studio (3D printer slicer) |
| `install_cleanmymac` | `true` | CleanMyMac 5 |
| `install_nextcloud` | `true` | Nextcloud client |
| `install_logi_options_plus` | `true` | Logi Options+ |
| `install_twingate` | `true` | Twingate client |
| `install_fish` | `true` | fish shell + dotfile |
| `install_starship` | `true` | Starship prompt |
| `install_tmux` | `true` | tmux + TPM |
| `install_git_config` | `true` | git user/email + 1Password SSH signing |
| `configure_macos_dock` | `true` | Dock layout (apps + folders) |
| `configure_macos_menubar` | `true` | Menu-bar clock format |
| `configure_macos_keyboard` | `true` | Key repeat rate |
| `configure_macos_screenshots` | `true` | Screenshot location/format |
| `configure_macos_finder` | `true` | Finder behavior |

Apps that don't ship as a Homebrew Cask (Okta Verify, Microsoft Remote Desktop / "Windows App", iMovie, Keynote/Pages/Numbers, etc.) install via the Mac App Store. Add their numeric IDs to the `mas_apps` map in `vars/vars.yml`. The user must already be signed in to the App Store; `mas` cannot sign in on modern macOS.

## Dock layout

The Dock is managed by `dockutil`. Apps are listed in `macos_dock_apps`; folders/stacks in `macos_dock_folders`. The dock task reads `dockutil --list` once and only adds entries that are missing, so the playbook stays idempotent.

To capture your *current* Dock into the playbook:

```sh
dockutil --list
```

Then translate each line into a `macos_dock_apps` or `macos_dock_folders` entry.

## Testing with Molecule

Two Molecule scenarios exist for parity with the Linux workstation playbooks. macOS itself can't be containerized, so the converge runs only the OS-agnostic structure of the playbook (the `macos` role and Homebrew tasks are gated on `ansible_facts['os_family'] == 'Darwin'` and skip on Linux). CI uses `molecule syntax` for parse-only validation; the converge / idempotence targets exist for parity but exercise the structural path only.

```sh
make test-podman          # full create/converge/idempotence/verify on podman
make test-docker          # same on docker
make syntax-podman        # parse-only check
make idempotence-podman   # converge twice, expect zero changes the second time
```

## Linting and CI

CircleCI runs five checks on every push (see `.circleci/config.yml`):

- `ansible-lint` — playbook & role linting
- `yamllint` — YAML quality
- `ansible-playbook --syntax-check` — playbook parses
- `molecule syntax` — molecule scenario parses
- `shellcheck` — shell scripts

Run them locally:

```sh
ansible-lint .
yamllint .
shellcheck run.sh
ansible-playbook --syntax-check setup_workstation.yml
```

## Customization

- Add/remove brew formulae: `vars/vars.yml` (`homebrew_formulae`)
- Add/remove brew casks: `vars/vars.yml` (`homebrew_casks` for unconditional, or add an `install_*` flag and an entry in `roles/third-party/tasks/main.yml`)
- macOS tweaks: `roles/macos/tasks/{defaults,finder,dock,menubar,keyboard,trackpad,screenshots}.yml`
- Dotfiles: drop a `.j2` into `templates/` and reference it from a role task

## Manual steps

Some apps cannot be fully automated:

- **1Password** — sign in with your account; enable the SSH agent under Settings → Developer
- **App Store apps** — sign in once, then `mas` will install IDs from `mas_apps`
- **Corporate-managed apps** (SentinelOne, Okta Verify, Self Service+, Twingate corporate config) — install via your MDM or company portal; this playbook only handles the cask form of `twingate`

## Related

- [`ansible-macos-workstation`](https://github.com/mtharpe/ansible-macos-workstation) — macOS (this repo)
- [`ansible-fedora-workstation-base`](https://github.com/mtharpe/ansible-fedora-workstation-base) — Fedora 43+
- [`ansible-ubuntu-workstation-base`](https://github.com/mtharpe/ansible-ubuntu-workstation-base) — Ubuntu 24.04+
- [`ansible-manjaro-workstation-base`](https://github.com/mtharpe/ansible-manjaro-workstation-base) — Manjaro/Arch

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
