# Coding Agent Guide

This file is for ChatGPT Codex, Claude Code, OpenCode, Pi, and other coding or
operations agents that install, verify, or operate `portp2p` from the public
distribution repository.

## Primary Reference

Before changing anything, read [README.md](README.md). The README is the
canonical public installation and usage reference for this repository. Use this
file as an agent-focused operating checklist, not as a replacement for the
README.

If this guide and the README ever disagree, prefer the README and then make a
minimal documentation update so both files match.

## Repository Scope

This repository is the public binary distribution for `portp2p`. It intentionally
does not contain the private source code.

Install released packages from Homebrew, APT, DNF/YUM, or GitHub release assets.
Do not request access to the private source repository for ordinary installation
or operation.

## Agent Safety Rules

- Do not store share codes, API keys, bearer tokens, private keys, or credentials
  in Git, shell history, screenshots, logs, or public documentation.
- Treat share codes as temporary passwords.
- Do not expose arbitrary hosts, subnets, filesystems, or shells. `portp2p`
  shares one TCP service on `127.0.0.1:<port>`.
- Prefer package-manager installs over manual binary downloads.
- After every install or config change, verify with the checklist below.
- Do not hardcode a public default rendezvous URL. Use `--server`,
  `PORTP2P_SERVER`, or a config file unless a release explicitly documents a
  default.
- For shared infrastructure, configure rate limits, relay limits, metrics
  scraping, and alerting.

## Decide The Machine Role

Ask or infer the role before making changes:

- Sharer: owns the local service and runs `portp2p share <port>`.
- Connector: opens a local listener and runs `portp2p connect <code>`.
- Infrastructure host: runs `portp2p server`, or split `portp2p rendezvous` and
  `portp2p relay`.

Also collect:

- operating system and architecture,
- local target port to share,
- desired connector bind port,
- rendezvous server URL,
- whether relay fallback is required,
- whether the host should run combined server mode or split rendezvous/relay,
- where persistent identity keys should live.

## Install By Platform

### macOS

```sh
brew tap yousef-muc/tap
brew install portp2p
portp2p version
```

### Ubuntu And Debian

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

### Fedora, RHEL, CentOS, And Compatible

```sh
sudo curl -fsSL https://yousef-muc.github.io/portp2p/rpm/portp2p.repo -o /etc/yum.repos.d/portp2p.repo
sudo dnf install portp2p
portp2p version
```

Use `yum install portp2p` on systems that use `yum` instead of `dnf`.

## Operate A Share

On the sharer:

```sh
portp2p share 3000 --plain --server http://SERVER_HOST:8080
```

Copy the printed code only to the intended connector.

On the connector:

```sh
portp2p connect <code> --plain --server http://SERVER_HOST:8080 --port 9000
```

Verify:

```sh
curl -I http://127.0.0.1:9000/
```

Stop both long-running processes with Ctrl+C when the share is no longer needed.

## Operate Infrastructure

Combined rendezvous plus relay:

```sh
portp2p server --plain \
  --listen 0.0.0.0:8080 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --identity /var/lib/portp2p/identity.key
```

Health and readiness:

```sh
curl http://SERVER_HOST:8080/healthz
curl http://SERVER_HOST:8080/readyz
curl http://SERVER_HOST:8080/metrics
```

Use explicit limits for infrastructure that serves more than one trusted user:

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

## Verification Checklist

After install:

```sh
portp2p version
portp2p --help
portp2p status --plain
```

After starting infrastructure:

```sh
curl http://SERVER_HOST:8080/healthz
curl http://SERVER_HOST:8080/readyz
curl http://SERVER_HOST:8080/metrics
```

After starting a share/connect pair:

```sh
curl -I http://127.0.0.1:<local-listener-port>/
```

Expected:

- `version` prints version, commit, date, Go version, OS/arch, and user agent.
- `status` prints configured server, log level, identity path, and control retry
  settings.
- `/healthz` reports `status: ok`.
- `/readyz` reports effective rendezvous limits.
- forwarded HTTP requests reach the sharer's local service.

## Troubleshooting

If `share` fails before registration:

- verify the target service is listening on `127.0.0.1:<port>`,
- increase `--target-check-timeout` for slow local services,
- use `--skip-target-check` only when the missing local target is deliberate.

If `connect` cannot listen:

- choose another `--port`,
- check for an existing process bound to that local port.

If direct dialing fails:

- verify the share publishes reachable addresses,
- use `--relay-only` to verify the relay path,
- run combined `portp2p server` or provide a relay address to `share --relay`.

If package installation fails:

- verify system architecture,
- verify repository key setup,
- check `portp2p version` after reinstall,
- prefer package-manager updates over replacing binaries by hand.

## Reporting Issues

Collect:

```sh
portp2p version
portp2p status --plain
```

Also record the role, operating system, architecture, rendezvous URL, selected
dial path, and sanitized output.

Never include live share codes or private identity keys.
