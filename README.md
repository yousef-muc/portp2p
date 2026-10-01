# portp2p - One-Port Localhost Sharing

[![Release](https://img.shields.io/github/v/release/yousef-muc/portp2p?label=release)](https://github.com/yousef-muc/portp2p/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-Homebrew-black.svg)](#macos-install)
[![Ubuntu/Debian](https://img.shields.io/badge/Linux-APT-orange.svg)](#ubuntu-and-debian-install)
[![Fedora/RHEL](https://img.shields.io/badge/Linux-DNF-red.svg)](#fedora-rhel-centos-and-compatible-install)
[![Agent Guide](https://img.shields.io/badge/AI%20Agent-Install%20Guide-7c3aed.svg)](AGENTS.md)

`portp2p` is a small CLI for sharing one local TCP service as localhost on
another computer.

The product goal is intentionally narrow: expose a service, not a machine. A
share is one temporary capability for one TCP port on `127.0.0.1:<port>`.

This repository is the public binary distribution for `portp2p`. It contains
release assets, package-manager instructions, and public documentation. The
private source repository publishes builds here.

## Install

### macOS Install

```sh
brew tap yousef-muc/tap
brew install portp2p
portp2p version
```

### Ubuntu And Debian Install

Use the one-line installer when you want the signed APT repository configured
for you:

```sh
curl -fsSL https://yousef-muc.github.io/portp2p/install.sh | sh
portp2p version
```

Manual APT setup:

```sh
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://yousef-muc.github.io/portp2p/apt/gpg/portp2p.gpg | sudo tee /usr/share/keyrings/portp2p-archive-keyring.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/portp2p-archive-keyring.gpg] https://yousef-muc.github.io/portp2p/apt stable main" | sudo tee /etc/apt/sources.list.d/portp2p.list >/dev/null
sudo apt update
sudo apt install portp2p
```

### Fedora, RHEL, CentOS, And Compatible Install

```sh
sudo curl -fsSL https://yousef-muc.github.io/portp2p/rpm/portp2p.repo -o /etc/yum.repos.d/portp2p.repo
sudo dnf install portp2p
portp2p version
```

Use `yum install portp2p` on systems that use `yum` instead of `dnf`.

### GitHub Release Assets

Release assets are available at:

```text
https://github.com/yousef-muc/portp2p/releases
```

Each release publishes:

- macOS tarballs for amd64 and arm64.
- Linux tarballs for amd64 and arm64.
- Windows zip archives for amd64 and arm64.
- Linux `.deb` packages for amd64 and arm64.
- Linux `.rpm` packages for amd64 and arm64.
- `checksums.txt`.

Verify downloaded assets:

```sh
shasum -a 256 -c checksums.txt
```

## Quickstart

On the machine that owns the local service:

```sh
portp2p share 3000 --plain --server http://SERVER_HOST:8080
```

Copy the printed code.

On the machine that should access the service:

```sh
portp2p connect <code> --plain --server http://SERVER_HOST:8080
```

By default, `connect` listens on the shared target port. Use `--port` to choose
a different local listener:

```sh
portp2p connect <code> --plain --server http://SERVER_HOST:8080 --port 9000
```

Open the service through the connector machine:

```sh
curl http://127.0.0.1:9000/
```

## Self-Hosted Server

Run combined rendezvous and relay infrastructure:

```sh
portp2p server --plain \
  --listen 0.0.0.0:8080 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --identity /var/lib/portp2p/identity.key
```

Open the HTTP port used by `--listen` and the libp2p TCP port used by
`--p2p-listen`.

The server exposes:

```sh
curl http://SERVER_HOST:8080/healthz
curl http://SERVER_HOST:8080/readyz
curl http://SERVER_HOST:8080/metrics
```

Use explicit limits for shared infrastructure:

```sh
portp2p server --plain \
  --listen 0.0.0.0:8080 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --rate-limit-requests 120 \
  --rate-limit-window 1m \
  --max-control-bytes 65536 \
  --max-sessions 10000 \
  --max-sessions-per-remote 16 \
  --max-addrs-per-share 32 \
  --relay-limit-duration 2m \
  --relay-limit-bytes 131072 \
  --relay-reservation-ttl 1h \
  --relay-max-reservations 128 \
  --relay-max-circuits 16
```

## Security Model

`portp2p` shares one localhost TCP port, not the whole machine.

Safety defaults:

- `share` targets only `127.0.0.1:<port>`.
- `connect` binds to `127.0.0.1` by default.
- Share codes are temporary bearer capabilities.
- Rendezvous stores only a hash of the share code.
- Tunnel streams require a capability proof before the share side opens the
  local target.
- Replay protection rejects repeated tunnel nonces.
- Rendezvous does not transport tunneled data.
- Circuit Relay provides reachability when direct dialing fails.

Handle share codes like temporary passwords. Do not paste them into public logs,
issue trackers, screenshots, or shared shell history.

## Common Commands

```sh
portp2p --help
portp2p version
portp2p status --plain
portp2p share 3000 --plain --server http://SERVER_HOST:8080
portp2p connect <code> --plain --server http://SERVER_HOST:8080
portp2p relay --plain --p2p-listen /ip4/0.0.0.0/tcp/4001
portp2p rendezvous --plain --listen 0.0.0.0:8080
portp2p server --plain --listen 0.0.0.0:8080 --p2p-listen /ip4/0.0.0.0/tcp/4001
```

## Update

Homebrew:

```sh
brew update
brew upgrade portp2p
```

APT:

```sh
sudo apt update
sudo apt install --only-upgrade portp2p
```

DNF:

```sh
sudo dnf upgrade portp2p
```

## Support Checks

When reporting an issue, include:

```sh
portp2p version
portp2p status --plain
```

Also mention:

- operating system and architecture,
- whether direct or relay dialing was used,
- the rendezvous URL,
- whether `share`, `connect`, `server`, `relay`, or `rendezvous` was running,
- sanitized command output without share codes.

Do not include live share codes in issue reports.
