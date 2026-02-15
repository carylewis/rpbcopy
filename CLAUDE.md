# CLAUDE.md

## Project overview

rpbcopy is a remote clipboard tool that lets you copy/paste between a local Mac and remote machines (Linux or Mac) over SSH. It uses `socat` to send data over TCP and reads `SSH_CLIENT` to discover the local Mac's IP with zero configuration.

## Architecture

**Data flow:** Remote machine reads `SSH_CLIENT` → sends stdin via socat to Mac's IP on port 2000 → Mac's socat listener pipes into `pbcopy`.

Three bash scripts in `bin/`:
- `rpbcopy-listen` — Mac-side listener. Runs two socat processes: one accepting clipboard data (port 2000, pipes to `pbcopy`), one serving clipboard contents (port 2001, runs `pbpaste`). The paste server runs in the background with cleanup via `trap`.
- `rpbcopy` — Remote-side copy. Parses `SSH_CLIENT` for the Mac's IP, handles IPv6 by wrapping in brackets, sends stdin via socat with a 5-second timeout.
- `rpbpaste` — Remote-side paste. Same IP discovery as rpbcopy, connects to port 2001 to retrieve clipboard contents.

## Project structure

```
bin/                  # All three scripts (bash, executable)
launchd/              # macOS launchd plist template for auto-start
examples/             # SSH config snippet for auto-starting listener
install.sh            # Installer — detects macOS vs Linux, handles sudo, offers launchd setup
```

## Conventions

- Pure bash, no dependencies beyond `socat`
- All scripts use `set -euo pipefail`
- All scripts have `--port` and `--help` flags
- Ports configurable via env vars: `RPBCOPY_PORT` (default 2000), `RPBPASTE_PORT` (default 2001)
- Error messages tell the user what to do (e.g., how to install socat, how to start the listener)
- IPv6 addresses detected by checking for `:` in the IP string

## Key decisions

- Listener runs both copy and paste servers in one process to keep usage simple
- The launchd plist is a template — `install.sh` substitutes actual paths at install time
- Connection timeout is 5 seconds to avoid hanging when the listener isn't running
- `socat fork` mode handles multiple sequential connections
