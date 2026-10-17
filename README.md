# Install Matcha on a Raspberry Pi Zero

Installs the [Matcha](https://github.com/floatpane/matcha) terminal email client on a Raspberry Pi Zero (32-bit ARMv6) by building it from source.

## Why this exists

Matcha's official install routes — Homebrew, Snap, and Flatpak — don't cover 32-bit ARM. A Pi Zero can't use any of them. This script does the thing that works: install Go, clone Matcha, and build it for `linux/arm` with `GOARM=6`.

## Requirements

- Raspberry Pi Zero / Zero W (ARMv6) or any `armv6l` / `armv7l` board
- Raspberry Pi OS 32-bit (or another Debian-based 32-bit ARM distro)
- Internet access
- `sudo` (used for `apt-get` and installing Go to `/usr/local/go`)

## Usage

```bash
chmod +x install-matcha.sh
./install-matcha.sh
```

## What it does

1. Verifies the architecture (warns and asks before continuing on anything other than ARMv6/v7)
2. Installs build dependencies: `git`, `gcc`, `make`, `ca-certificates`, `curl`
3. Installs Go 1.22.4 for ARMv6 if Go is missing or older than 1.21 (existing Go ≥ 1.21 is left alone)
4. Clones Matcha and builds it with `GOOS=linux GOARCH=arm GOARM=6`
5. Installs the binary to `~/.local/bin/matcha` and adds that directory (and Go) to your `PATH`
6. Verifies the install and prints next steps

## After installing

```bash
source ~/.bashrc   # or open a new terminal
matcha             # add your email account when prompted (IMAP/SMTP)
```

Config lives at `~/.config/matcha/config.json`.

Keyboard shortcuts inside Matcha:

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate up / down |
| `Enter` | Open email |
| `Tab` | Switch accounts |
| `r` | Refresh inbox |
| `q` / `Esc` | Go back / quit |

## Notes

- This builds the latest Matcha from source (default branch), not a pinned release.
- Installing Go replaces `/usr/local/go` if it already exists there.
- Not affiliated with the Matcha project — this is just an installer for it.

## License

MIT — see [LICENSE](LICENSE). Use it, fork it, improve it.

## Questions or bugs

Please open an [Issue](../../issues) on this repo.
