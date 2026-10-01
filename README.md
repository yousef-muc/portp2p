# portp2p - One-Port Localhost Sharing

<!-- Replace this placeholder without changing the path when the final hero is ready. -->
![portp2p hero](./artifacts/general/img/hero.png)

[![Release](https://img.shields.io/github/v/release/yousef-muc/portp2p?label=release)](https://github.com/yousef-muc/portp2p/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS](https://img.shields.io/badge/macOS-Homebrew-black.svg)](#macos)
[![Ubuntu/Debian](https://img.shields.io/badge/Linux-APT-orange.svg)](#ubuntu-and-debian)
[![Fedora/RHEL](https://img.shields.io/badge/Linux-DNF-red.svg)](#fedora-rhel-centos-and-compatible-systems)
[![Windows](https://img.shields.io/badge/Windows-Release%20ZIP-0078d4.svg)](#windows)
[![Agent Guide](https://img.shields.io/badge/AI%20Agent-Install%20Guide-7c3aed.svg)](AGENTS.md)

`portp2p` makes one TCP service on one computer available as localhost on
another computer. Start a share, send the temporary code to the intended
recipient, and connect. The remote service then behaves like a local port.

It works with HTTP, WebSockets, Server-Sent Events, streaming responses, and
arbitrary TCP protocols. That makes it suitable for development servers,
ComfyUI, dashboards, databases, SSH test endpoints, and other local tools that
must stay bound to localhost.

The scope is deliberately narrow: `portp2p` shares one port, not a shell, a
filesystem, or the rest of the machine.

This repository is the public distribution for `portp2p`. It contains signed
package repositories, release binaries, checksums, and user documentation.

## At A Glance

| Property | Behavior |
| --- | --- |
| Shared resource | One service at `127.0.0.1:<port>` |
| Connector listener | `127.0.0.1:<port>` by default |
| Access credential | Random, temporary share code |
| Data path | Direct libp2p connection when possible; Circuit Relay fallback |
| Encryption | Authenticated libp2p transport encryption end to end |
| Rendezvous visibility | Hashed code, peer addresses, capabilities, and expiry; no tunneled payload |
| Browser applications | HTTP, WebSockets, SSE, uploads, and downloads pass transparently |
| Restricted networks | HTTPS rendezvous plus WSS relay through HTTP CONNECT or SOCKS5 proxies |
| Platforms | macOS, Linux, and Windows on amd64 and arm64 |

## Installation

Install the `portp2p` package on both computers.

### macOS

```sh
brew tap yousef-muc/tap
brew install portp2p
portp2p version
```

Update later with:

```sh
brew update
brew upgrade portp2p
```

### Ubuntu And Debian

The one-line installer configures the signed APT repository and installs the
package:

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

Update later with:

```sh
sudo apt update
sudo apt install --only-upgrade portp2p
```

### Fedora, RHEL, CentOS, And Compatible Systems

```sh
sudo curl -fsSL https://yousef-muc.github.io/portp2p/rpm/portp2p.repo -o /etc/yum.repos.d/portp2p.repo
sudo dnf install portp2p
portp2p version
```

Use `yum install portp2p` on systems that provide `yum` instead of `dnf`.

Update later with:

```sh
sudo dnf upgrade portp2p
```

### Windows

1. Download the Windows archive for your architecture from
   [GitHub Releases](https://github.com/yousef-muc/portp2p/releases).
2. Extract `portp2p.exe` into a directory on your `PATH`.
3. Open PowerShell and verify the binary:

```powershell
portp2p version
```

### Release Assets

Every release provides:

| Platform | Architecture | Format |
| --- | --- | --- |
| macOS | amd64, arm64 | `.tar.gz` |
| Linux | amd64, arm64 | `.tar.gz`, `.deb`, `.rpm` |
| Windows | amd64, arm64 | `.zip` |

The release also includes `checksums.txt`. Verify a manually downloaded asset
before installing it:

```sh
grep 'portp2p_VERSION_darwin_arm64.tar.gz' checksums.txt | shasum -a 256 -c -
```

PowerShell:

```powershell
Get-FileHash .\portp2p_VERSION_windows_amd64.zip -Algorithm SHA256
```

Compare the printed value with the matching entry in `checksums.txt`.

## Quick Start

Both computers must use the same rendezvous service. A release may contain a
preconfigured service URL; `portp2p version --plain` shows it. If no default is
listed, set the URL supplied by your administrator or run your own server:

```sh
export PORTP2P_SERVER=https://relay.example.com
```

Use `--server https://relay.example.com` on each command instead when you do
not want to set an environment variable.

### 1. Start The Local Application

On the computer that owns the service, make sure it is reachable on localhost.
For example:

```sh
curl http://127.0.0.1:3000/
```

### 2. Share The Port

```sh
portp2p share 3000 --plain
```

The command prints a temporary code and stays running. Send only that code to
the intended recipient. The default lifetime is 10 minutes; choose another
lifetime with `--expires`:

```sh
portp2p share 3000 --plain --expires 30m
```

### 3. Connect From The Other Computer

```sh
portp2p connect <share-code> --plain
```

`connect` recreates the shared target port on `127.0.0.1`. Open it exactly as
if the application were running locally:

```sh
curl http://127.0.0.1:3000/
```

If that port is already in use, choose another local port:

```sh
portp2p connect <share-code> --plain --port 9000
curl http://127.0.0.1:9000/
```

Press `Ctrl+C` on either computer to stop its process. Stopping `share` closes
the rendezvous registration immediately.

## ComfyUI And Browser Applications

ComfyUI normally listens on port `8188`. Start ComfyUI locally, then share it:

```sh
portp2p share 8188 --plain --expires 2h
```

On the other computer:

```sh
portp2p connect <share-code> --plain
```

Open `http://127.0.0.1:8188` in the browser. ComfyUI's HTTP requests, image
uploads, generated output, queue events, and progress WebSocket use the same
TCP tunnel. No application-specific WebSocket option is required.

The same behavior applies to other browser applications. If an application
embeds an absolute hostname in its own responses, configure that application
to use its local URL or the connector address.

## How It Works

<!-- Replace this placeholder without changing the path when the final architecture image is ready. -->
![portp2p connection architecture](./artifacts/general/img/how.png)

1. `share` creates a random code, hashes it, starts a libp2p peer, and registers
   the peer's reachable addresses with rendezvous.
2. The plain code stays with the two users. Rendezvous receives only its hash.
3. `connect` resolves the hash, creates a localhost listener, and tries a direct
   encrypted libp2p connection.
4. If direct connectivity is unavailable, it retries through the discovered
   Circuit Relay. Relay addresses are obtained from the rendezvous service, so
   infrastructure operators can move relays without requiring a new client
   release.
5. Every tunnel stream must prove possession of the share code before `share`
   opens a connection to the local target.
6. Bytes are copied end to end without interpreting the application protocol.

### Connection Paths

| Path | Typical use | Payload visibility |
| --- | --- | --- |
| Direct TCP or QUIC | Peers can reach each other directly | Encrypted between the two portp2p peers |
| Circuit Relay over TCP | NAT or firewall prevents direct dialing | Relay forwards encrypted libp2p traffic |
| Circuit Relay over WSS | Corporate proxy or HTTPS-only egress | Proxy and relay carry encrypted libp2p traffic |

Run `connect` with `--verbose` to see selected and skipped addresses. The plain
output reports `Connection: DIRECT` or `Connection: RELAY` after dialing.

For diagnostics, force one path:

```sh
portp2p connect <share-code> --plain --direct-only
portp2p connect <share-code> --plain --relay-only
```

## Proxies And Restricted Networks

`portp2p` honors standard proxy environment variables for rendezvous HTTP(S)
and WSS relay traffic:

```sh
export HTTPS_PROXY=http://user:password@proxy.example.com:3128
export HTTP_PROXY=http://user:password@proxy.example.com:3128
export NO_PROXY=127.0.0.1,localhost
portp2p connect <share-code> --plain
```

To use one explicit HTTP CONNECT or SOCKS5 proxy for both control traffic and
WSS relay traffic:

```sh
export PORTP2P_PROXY=http://user:password@proxy.example.com:3128
portp2p connect <share-code> --plain
```

SOCKS5 example:

```sh
export PORTP2P_PROXY=socks5://127.0.0.1:1080
```

The equivalent one-command option is `--proxy`. Prefer the environment or a
private config file when the proxy URL contains credentials, because command
arguments may be visible in shell history or process listings.

Native TCP and QUIC do not pass through a conventional HTTP proxy. The
rendezvous operator must publish a WSS relay address for users on restrictive
networks. When proxy configuration and WSS are both available, `connect`
prefers the WSS relay path to avoid waiting for native transport timeouts.

`portp2p status --plain` reports whether proxy configuration came from an
explicit portp2p setting, standard environment variables, or is absent. It
never prints proxy credentials.

## Configuration

Configuration precedence is:

1. Command-line flags.
2. `PORTP2P_*` environment variables.
3. A JSON file passed with `--config` or `PORTP2P_CONFIG`.
4. Build defaults.

Example config file:

```json
{
  "server_url": "https://relay.example.com",
  "log_level": "info",
  "identity_path": "/home/user/.config/portp2p/identity.key",
  "proxy_url": ""
}
```

Use it with:

```sh
portp2p --config /path/to/portp2p.json status --plain
```

| Environment variable | Equivalent flag | Purpose |
| --- | --- | --- |
| `PORTP2P_CONFIG` | `--config` | JSON config file path |
| `PORTP2P_SERVER` | `--server` | Rendezvous service URL |
| `PORTP2P_IDENTITY` | `--identity` | Persistent libp2p private-key path |
| `PORTP2P_PROXY` | `--proxy` | HTTP CONNECT or SOCKS5 proxy URL |
| `PORTP2P_LOG_LEVEL` | `--log-level` | `debug`, `info`, `warn`, or `error` |
| `HTTP_PROXY` / `HTTPS_PROXY` | none | Standard proxy fallback |
| `NO_PROXY` | none | Hosts that bypass the standard proxy |

By default, the peer identity is stored in the operating system's user config
directory. Keep this file private. Removing it creates a new peer identity on
the next run.

## Self-Hosting

One `portp2p server` process can provide both rendezvous and Circuit Relay.
The rendezvous API coordinates peers; it does not carry tunneled application
data. The relay forwards encrypted traffic only when a direct connection is not
possible.

### Local Or Private-Network Setup

Start the combined service:

```sh
portp2p server --plain \
  --listen 0.0.0.0:8080 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --identity /var/lib/portp2p/identity.key
```

Clients use:

```sh
export PORTP2P_SERVER=http://SERVER_HOST:8080
```

Allow TCP ports `8080` and `4001` through the host firewall. Plain HTTP is
appropriate only on a trusted private network or for local testing.

### Public HTTPS And WSS Setup

For public infrastructure, expose:

| Public endpoint | Internal destination | Purpose |
| --- | --- | --- |
| `https://relay.example.com` on TCP 443 | `127.0.0.1:8080` | Rendezvous API |
| `wss://relay.example.com` on TCP 443 | `127.0.0.1:4002` | Proxy-compatible libp2p relay |
| TCP 4001 | TCP 4001 | Native libp2p relay |

Run the server once with the persistent identity to obtain its Peer ID. Then
restart it with public relay addresses that contain that same ID:

```sh
portp2p server --plain \
  --listen 127.0.0.1:8080 \
  --trusted-proxy 127.0.0.1 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --p2p-listen /ip4/127.0.0.1/tcp/4002/ws \
  --advertise-relay /dns4/relay.example.com/tcp/443/tls/ws/p2p/<peer-id> \
  --advertise-relay /dns4/relay.example.com/tcp/4001/p2p/<peer-id> \
  --identity /var/lib/portp2p/identity.key
```

Keep the WSS address first. A share reserves one relay and advertises all
discovered transports for that relay peer, allowing each connector to choose
WSS 443 or native TCP independently.

A minimal Caddy configuration:

```caddyfile
relay.example.com {
    @libp2p_websocket {
        header Connection *Upgrade*
        header Upgrade websocket
    }

    handle @libp2p_websocket {
        reverse_proxy 127.0.0.1:4002
    }

    handle {
        reverse_proxy 127.0.0.1:8080
    }
}
```

Do not expose the plain WebSocket listener on port `4002` directly. Configure
`--trusted-proxy` only for reverse-proxy addresses or CIDRs you control. Other
clients cannot use forwarded headers to bypass per-address limits.

### Health And Operations

```sh
curl https://relay.example.com/healthz
curl https://relay.example.com/readyz
curl https://relay.example.com/metrics
curl https://relay.example.com/v1/info
```

`/v1/info` is the relay-discovery endpoint consumed by clients. Health and
readiness return success only while the control service can accept requests.

Relevant production defaults include:

| Limit | Default |
| --- | --- |
| Share lifetime | 10 minutes |
| Maximum share lifetime | 24 hours |
| Control request body | 64 KiB |
| Control requests per source | 120 per minute |
| Active rendezvous sessions | 10,000 |
| Active sessions per source | 16 |
| Peer addresses per share | 32 |
| Relay connection duration | 24 hours |
| Relay data per direction | 10 GiB |
| Concurrent relay circuits per peer | 64 |

Keep finite limits on public infrastructure and tune them for expected traffic.
See `portp2p server --help` for every resource and timeout option.

## Security Model

Share codes are temporary bearer capabilities. Anyone who has a live code can
connect to that one shared port until the share is stopped or expires.

Security properties:

- `share` targets only `127.0.0.1:<port>`.
- `connect` listens only on `127.0.0.1` unless `--bind` is explicitly changed.
- Rendezvous stores a hash of the code, never the plain code.
- Tunnel streams authenticate possession of the code before the target opens.
- Replay protection rejects reused tunnel authentication nonces.
- Unauthenticated handshakes have strict concurrency and time limits.
- A running share restores its registration after a rendezvous restart without
  extending the original expiry.
- libp2p authenticates peers and encrypts direct and relayed transport.
- Rendezvous never sees tunneled payload data.

Operational rules:

- Treat a share code like a temporary password.
- Send it through a private channel.
- Do not include live codes in logs, screenshots, issue reports, or shell
  transcripts.
- Keep `connect` on its default loopback bind unless LAN exposure is intended.
- Put public rendezvous traffic behind HTTPS.
- Protect the server identity key and back it up securely.
- Keep the CLI and server on supported release versions.

`portp2p` protects the transport. It does not add authentication to the
application being shared. Application-level accounts, permissions, and data
handling still apply.

## Command Reference

| Command | Purpose |
| --- | --- |
| `portp2p share <port>` | Create and serve a temporary one-port share |
| `portp2p connect <code>` | Recreate a shared service on localhost |
| `portp2p status` | Show identity, configuration, and local reachability |
| `portp2p server` | Run combined rendezvous and relay infrastructure |
| `portp2p rendezvous` | Run only the control service |
| `portp2p relay` | Run only the Circuit Relay service |
| `portp2p version` | Print build and platform information |
| `portp2p completion <shell>` | Generate shell completion |

Useful global output modes:

```sh
portp2p status --plain
portp2p status --json
portp2p connect <share-code> --plain --verbose
```

Use `--json` for scripts. Errors also use structured JSON when that mode is
selected. Run `portp2p <command> --help` for the full option list.

## Troubleshooting

### No Rendezvous Server Is Configured

Set the same URL on both computers:

```sh
export PORTP2P_SERVER=https://relay.example.com
portp2p status --plain
```

### Share Refuses To Start

`share` checks `127.0.0.1:<port>` before registering. Confirm the application
is running and bound to the expected port:

```sh
curl http://127.0.0.1:3000/
lsof -nP -iTCP:3000 -sTCP:LISTEN
```

Use `--skip-target-check` only when the service intentionally starts after the
share.

### The Local Port Is Already In Use

Choose another connector port:

```sh
portp2p connect <share-code> --port 9000 --plain
```

### Direct Dialing Fails

The normal connection strategy automatically retries through the discovered
relay. Confirm the server publishes relay addresses:

```sh
curl https://relay.example.com/v1/info
```

Then run the connector with `--verbose`, or isolate the relay path:

```sh
portp2p connect <share-code> --relay-only --plain --verbose
```

### Corporate Proxy Connection Fails

Confirm `HTTPS_PROXY` or `PORTP2P_PROXY` is set and that `/v1/info` publishes a
`/tls/ws/` relay address on a permitted port such as 443. Add local destinations
to `NO_PROXY` when required.

### Browser Opens But Live Updates Do Not Work

No WebSocket setting is needed on the two clients. If a public reverse proxy is
in front of the portp2p relay, verify that it forwards `Connection: Upgrade`
and `Upgrade: websocket` to the relay's internal WebSocket listener.

### Collect Diagnostics

```sh
portp2p version --plain
portp2p status --plain
portp2p connect <share-code> --plain --verbose
```

Remove the share code, proxy credentials, private addresses, and other secrets
before posting output publicly.

## Uninstall

Homebrew:

```sh
brew uninstall portp2p
brew untap yousef-muc/tap
```

APT:

```sh
sudo apt remove portp2p
sudo rm -f /etc/apt/sources.list.d/portp2p.list
sudo rm -f /usr/share/keyrings/portp2p-archive-keyring.gpg
```

DNF:

```sh
sudo dnf remove portp2p
sudo rm -f /etc/yum.repos.d/portp2p.repo
```

The persistent identity remains in the user config directory after package
removal. Delete it separately only when a future install should use a new peer
identity.

## Support And Issues

Use [GitHub Issues](https://github.com/yousef-muc/portp2p/issues) for confirmed
bugs and focused feature requests. Include the diagnostics above, operating
system, architecture, whether the connection was direct or relayed, and whether
a proxy was involved. Never include a live share code or credentials.

For AI-assisted installation and operations, see [AGENTS.md](AGENTS.md).

## License

`portp2p` is distributed under the [MIT License](LICENSE).
