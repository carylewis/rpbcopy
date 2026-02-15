# rpbcopy

**Remote clipboard over SSH.** Copy and paste between your Mac and any remote machine, with zero configuration.

```
ssh devbox
cat deploy.log | rpbcopy     # it's on your Mac clipboard now
```

## How it works

When you SSH into a machine, the remote shell knows your IP — it's stored in `SSH_CLIENT`. rpbcopy uses this to send clipboard data back to a listener running on your Mac, over a simple TCP connection via `socat`.

No port forwarding. No reverse tunnels. No config files. The SSH session already proves trust.

```
┌──────────────────────┐          ┌──────────────────────┐
│     Remote Machine   │          │      Your Mac        │
│                      │          │                      │
│  echo "hi" | rpbcopy │──TCP────▶│  rpbcopy-listen      │
│                      │  :2000   │    └─▶ pbcopy        │
│  rpbpaste            │◀─TCP────│                      │
│                      │  :2001   │    └─▶ pbpaste       │
└──────────────────────┘          └──────────────────────┘
         reads $SSH_CLIENT to find Mac's IP
```

## Quick start

**On your Mac** (one time):

```bash
brew install socat
git clone https://github.com/yourusername/rpbcopy.git
cd rpbcopy && ./install.sh
rpbcopy-listen
```

**On the remote machine** (one time):

```bash
# install socat
sudo apt install socat    # Debian/Ubuntu
sudo yum install socat    # RHEL/CentOS

# copy the scripts
scp bin/rpbcopy bin/rpbpaste remote:~/bin/
# or just curl them into place
```

**Use it:**

```bash
ssh remote-machine
echo "hello from the server" | rpbcopy    # now on your Mac clipboard
rpbpaste > clipboard.txt                  # Mac clipboard → remote file
```

## Usage examples

```bash
# Copy command output
uptime | rpbcopy

# Copy a file
cat ~/.ssh/id_rsa.pub | rpbcopy

# Copy the last command's output
!! | rpbcopy

# Grab your Mac's clipboard on the remote machine
rpbpaste

# Pipe your Mac's clipboard into a command
rpbpaste | wc -l
```

## Installation

### macOS (listener side)

```bash
./install.sh
```

The installer will:
- Place `rpbcopy-listen`, `rpbcopy`, and `rpbpaste` in `/usr/local/bin`
- Optionally set up a launchd service so the listener starts on login

### Linux (remote side)

```bash
./install.sh
```

Or manually copy `bin/rpbcopy` and `bin/rpbpaste` to somewhere in your `$PATH`.

### Verifying the install

```bash
# On your Mac — start the listener
rpbcopy-listen

# On the remote machine
echo "test" | rpbcopy

# Back on your Mac
pbpaste   # → "test"
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `RPBCOPY_PORT` | `2000` | Port for sending clipboard data (copy) |
| `RPBPASTE_PORT` | `2001` | Port for retrieving clipboard data (paste) |

You can also pass `--port` to any of the scripts:

```bash
rpbcopy-listen --port 3000          # listen on 3000 (copy) and 3001 (paste)
echo "hi" | rpbcopy --port 3000     # send to port 3000
rpbpaste --port 3001                # read from port 3001
```

### Auto-start on login (macOS)

The installer can set up a launchd service, or do it manually:

```bash
cp launchd/com.rpbcopy.listener.plist ~/Library/LaunchAgents/
launchctl load -w ~/Library/LaunchAgents/com.rpbcopy.listener.plist
```

### Auto-start with SSH

Add to your `~/.ssh/config`:

```
Host *
    PermitLocalCommand yes
    LocalCommand rpbcopy-listen --daemon 2>/dev/null
```

## How it compares

| Approach | Pros | Cons |
|---|---|---|
| **rpbcopy** | Zero config, works everywhere, simple | Requires socat, opens a port |
| OSC 52 | No extra tools needed | Terminal must support it, many don't |
| X11 forwarding | Native clipboard support | Slow, heavy, X11 only |
| tmux/screen | Built-in buffer sharing | Only within the session |
| Apple Universal | Seamless between Apple devices | Mac-to-Mac only |

## Security

rpbcopy's trust model matches SSH: if someone can reach port 2000 on your Mac, they could send data to your clipboard. In practice:

- Your Mac's firewall blocks external connections by default
- The listener only runs while you need it (or on login via launchd)
- Data flows over your local network, same as SSH itself
- You can bind to `localhost` and use SSH port forwarding for extra isolation

For sensitive environments, use SSH remote forwarding instead:

```bash
ssh -R 2000:localhost:2000 remote-machine
```

This tunnels the clipboard port through SSH encryption.

## Dependencies

- **socat** — the only dependency, on both sides
  - macOS: `brew install socat`
  - Debian/Ubuntu: `sudo apt install socat`
  - RHEL/CentOS: `sudo yum install socat`
- **bash** — any modern version
- **pbcopy/pbpaste** — macOS built-in (listener side only)

## Project structure

```
rpbcopy/
├── README.md
├── LICENSE
├── install.sh
├── bin/
│   ├── rpbcopy-listen     # Mac-side listener
│   ├── rpbcopy            # Remote → Mac clipboard
│   └── rpbpaste           # Mac clipboard → remote
├── launchd/
│   └── com.rpbcopy.listener.plist
└── examples/
    └── ssh-config-snippet
```

## License

MIT
>>>>>>> f0281c0 (Initial release of rpbcopy — remote clipboard over SSH)
