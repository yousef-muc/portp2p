# Coding Agent Guide

This guide is for ChatGPT Codex, Claude Code, OpenCode, Pi, and other coding or
operations agents that install, configure, verify, or operate `portp2p` from
the public distribution repository.

## Primary Reference

Read [README.md](README.md) before making changes. The README is the canonical
public reference for product behavior, installation, networking, security, and
troubleshooting. This file turns that material into an agent-oriented runbook;
it does not replace the README.

If the two documents disagree, follow the README and make the smallest safe
documentation correction needed to bring them back into agreement.

## Repository Scope

This repository is the public binary distribution for `portp2p`. It contains
release archives, package repository metadata, checksums, and public
documentation. It intentionally does not contain the private source code.

For ordinary installation and operation:

- install from Homebrew, APT, DNF/YUM, or a GitHub Release;
- do not request private source access;
- do not build an unofficial replacement binary;
- do not modify release or package-repository files by hand;
- use [GitHub Releases](https://github.com/yousef-muc/portp2p/releases) as the
  authoritative source for manual downloads.

## Product Boundary

`portp2p` shares one TCP service at `127.0.0.1:<port>` and recreates it as a
localhost listener on another computer. It does not share a machine, shell,
filesystem, subnet, or arbitrary network route.

Application protocols pass through the byte stream without special handling.
This includes HTTP, WebSockets, Server-Sent Events, streaming responses, and
raw TCP protocols.

The main components are:

- `share`: owns the local target and serves authenticated tunnel streams;
- `connect`: creates the connector's local listener;
- `discover`: searches explicitly public, temporary service listings;
- `access`: opens private invitations and manages requester-side approval;
- `web`: runs the loopback-only local browser interface;
- rendezvous: stores temporary peer metadata under a hash of the share code;
- Circuit Relay: forwards encrypted libp2p traffic when direct dialing fails.

Rendezvous is the control plane, not the application data path. Relay traffic
remains encrypted between the two portp2p peers.

## Non-Negotiable Safety Rules

- Treat every live share code as a temporary password.
- Never publish a share unless the user explicitly requests discovery.
- Confirm visibility (`public` search or `private` invitation) and access
  (`direct` or `approval`) when publishing on the user's behalf.
- Make clear that public direct Discovery v1 allows anyone finding the listing
  to connect without an approval step.
- Treat private invitation codes and access request tokens as secrets.
- Never write share codes, proxy credentials, private keys, access tokens, or
  other secrets into Git, logs, screenshots, issue reports, or public docs.
- Do not repeat a user-provided share code in the final response. Redact it.
- Do not change `connect` from its default loopback bind unless the user
  explicitly requests LAN or public exposure and understands the consequence.
- Do not add arbitrary target-host options. A share targets localhost only.
- Do not use `--skip-target-check` unless the target is intentionally expected
  to start later.
- Do not disable server or relay limits for public infrastructure.
- Do not trust `X-Forwarded-For` from the internet. Add `--trusted-proxy` only
  for reverse-proxy addresses or CIDRs the operator controls.
- Do not expose a plain WebSocket relay listener directly to the internet.
- Never bind, reverse proxy, or otherwise expose `portp2p web` outside the
  local machine. It is a client UI, not an infrastructure admin console.
- Do not use plain HTTP for a public rendezvous endpoint.
- Do not overwrite or delete an existing identity key. Back it up before an
  intentional identity rotation.
- Do not stop another user's running share, connector, or infrastructure
  process without explicit approval.
- Prefer package-manager installs and updates over manually replacing binaries.
- Ask before changing firewalls, reverse proxies, system services, DNS, or
  privileged filesystem ownership.
- Never claim installation or connectivity succeeded without checking command
  output.

## Decide The Machine Role

Determine the role before running commands:

- Sharer: owns the local application and runs `portp2p share <port>`.
- Connector: receives a code and runs `portp2p connect <code>`.
- Discovery user: searches public listings with `portp2p discover`.
- Access requester: opens an invitation or requests an owner-approved grant
  with `portp2p access`.
- Infrastructure host: runs combined `portp2p server`, or separate rendezvous
  and relay processes.
- Multi-role host: performs more than one role intentionally, such as local
  infrastructure plus a test share.

Collect only the information needed for that role:

- operating system and architecture;
- installed `portp2p` version;
- local target port on the sharer;
- desired listener port on the connector;
- rendezvous URL shared by both peers;
- whether a corporate HTTP CONNECT or SOCKS5 proxy is required;
- whether direct connectivity, relay fallback, or WSS-only egress is expected;
- for infrastructure, public DNS name, reverse proxy, open ports, service
  account, and persistent identity-key location.

Do not ask an ordinary sharer or connector to deploy infrastructure when a
working rendezvous URL is already available.

## Install By Platform

Use the package manager for the host whenever possible. After installation,
always run `portp2p version --plain` and verify that the reported OS and
architecture match the machine.

### macOS

```sh
brew tap yousef-muc/tap
brew install portp2p
portp2p version --plain
```

For an existing installation:

```sh
brew update
brew upgrade portp2p
portp2p version --plain
```

### Ubuntu And Debian

Preferred installer:

```sh
curl -fsSL https://yousef-muc.github.io/portp2p/install.sh | sh
portp2p version --plain
```

Manual APT setup:

```sh
sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://yousef-muc.github.io/portp2p/apt/gpg/portp2p.gpg | sudo tee /usr/share/keyrings/portp2p-archive-keyring.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/portp2p-archive-keyring.gpg] https://yousef-muc.github.io/portp2p/apt stable main" | sudo tee /etc/apt/sources.list.d/portp2p.list >/dev/null
sudo apt update
sudo apt install portp2p
portp2p version --plain
```

Update:

```sh
sudo apt update
sudo apt install --only-upgrade portp2p
portp2p version --plain
```

### Fedora, RHEL, CentOS, And Compatible Systems

```sh
sudo curl -fsSL https://yousef-muc.github.io/portp2p/rpm/portp2p.repo -o /etc/yum.repos.d/portp2p.repo
sudo dnf install portp2p
portp2p version --plain
```

Use `yum install portp2p` when the system provides `yum` instead of `dnf`.

Update:

```sh
sudo dnf upgrade portp2p
portp2p version --plain
```

### Windows

1. Determine whether the machine is amd64 or arm64.
2. Download the matching archive and `checksums.txt` from GitHub Releases.
3. Compare the archive's SHA-256 digest with the checksum file.
4. Extract `portp2p.exe` into a directory on `PATH`.
5. Verify it in PowerShell.

```powershell
Get-FileHash .\portp2p_VERSION_windows_amd64.zip -Algorithm SHA256
portp2p version --plain
```

Do not disable antivirus or execution-policy protections to work around a
failed installation. Diagnose the exact block and ask the user before changing
host security policy.

### Manual Release Assets

Use manual archives only when a supported package manager is unavailable.
Download the archive and `checksums.txt` from the same release. Verify only the
selected file, for example:

```sh
grep 'portp2p_VERSION_linux_amd64.tar.gz' checksums.txt | sha256sum -c -
```

Do not infer success from a completed download; confirm the digest and run the
installed binary.

## Resolve Rendezvous Configuration

Both peers must use the same rendezvous service.

First inspect the release and effective configuration:

```sh
portp2p version --plain
portp2p status --plain
```

Official builds default to `https://portp2p.com`. `version` prints the build
default and `status` prints the effective configuration. The server supplies
its current native and WSS relay addresses dynamically through `/v1/info`.

Use an operator-approved self-hosted service when the user requests one:

```sh
export PORTP2P_SERVER=https://relay.example.com
portp2p status --plain
```

The equivalent one-command form is:

```sh
portp2p share 3000 --server https://relay.example.com --plain
```

Configuration precedence is:

1. command-line flag;
2. `PORTP2P_*` environment variable;
3. JSON config file;
4. build default.

Before diagnosing different behavior on two computers, compare their effective
server URLs and versions.

## Operate The Local Web UI

Use the embedded interface when the user prefers browser controls:

```sh
portp2p web
```

Open the printed loopback URL. It uses `https://portp2p.com` unless the user
overrides the server through configuration or the local Server dialog. The
interface can share, connect, search public discovery, open private
invitations, request or decide access, publish or unpublish a share, and stop
sessions created by that Web UI process. Its Server
dialog can change the rendezvous URL only after all active sessions are stopped.
Optional relay fields override automatic relay discovery for one operation.

A normal Web UI share remains private unless the user explicitly enables
discovery. Published visibility and access are independent. Never expose the
local HTTP port, place it behind a reverse proxy, or describe it as a remote
administration dashboard. Closing the tab does not end active sessions; stop
them in the Sessions view or stop the Web UI process with Ctrl+C.

## Operate A Share Safely

### 1. Verify The Target

Confirm that the intended application is listening on localhost. For HTTP:

```sh
curl http://127.0.0.1:3000/
```

For a generic TCP service:

```sh
nc -vz 127.0.0.1 3000
```

Do not change the application to a public bind merely to use `portp2p`.

### 2. Start The Sharer

```sh
portp2p share 3000 --plain
```

Use an intentional expiry when the default 10 minutes is too short:

```sh
portp2p share 3000 --plain --expires 2h
```

The process must remain running. Share the printed code only through the user's
chosen private channel. Do not paste it into the agent's summary.

### 3. Start The Connector

The connector defaults to the original target port:

```sh
portp2p connect <share-code> --plain
```

If that local port is occupied, choose another loopback port:

```sh
portp2p connect <share-code> --plain --port 9000
```

Do not use `--bind 0.0.0.0` unless the user explicitly wants the reconstructed
service exposed to the connector's network.

### 4. Verify End To End

For HTTP:

```sh
curl -I http://127.0.0.1:9000/
```

For a browser application, ask the user to open the connector's localhost URL
and verify the workflow that matters, including any live updates or uploads.

Successful process startup alone does not prove that the target application is
usable through the tunnel.

### 5. Stop Cleanly

Use `Ctrl+C` for the connector and sharer when the session is finished. Stopping
the sharer closes its rendezvous registration. Do not leave a long expiry
running after the user no longer needs access.

## Operate Discovery And Access Safely

A normal share is private. Use public discovery only after the user explicitly
chooses unrestricted temporary public access:

```sh
portp2p share 3000 --plain \
  --publish --name "Demo service" --category demo --tag http
```

The output contains a private code and a separate public connect code. Never
expose the private code. Search and connect with:

```sh
portp2p discover demo --plain
portp2p connect <public-connect-code> --plain
```

Confirm the listing disappears after the sharer stops. Discovery v1 has no
accounts, payments, or approval. Keep application authentication enabled for
sensitive public direct services.

For signed Discovery v2 and Access v3, first preserve the user's configured
identity. Approval and private listings require a stable service key:

```sh
portp2p share 3000 --plain \
  --publish --name "Demo by request" \
  --service-key demo-home --access approval
```

A public requester uses the stable Service ID:

```sh
portp2p access request <service-id> --message "Reason for access" --plain
```

The running sharer accepts `approve <request-id>` or `deny <request-id>`.
Approved codes are temporary and bound to the requester's libp2p identity.
Never approve a request merely because it contains a persuasive message; show
the requester Peer ID and leave the trust decision to the human owner.

For invitation-only discovery, add `--visibility private`. Private listings
must never appear in `portp2p discover` output or public result counts. Give the
separate invitation only to intended recipients. They use
`portp2p access open <invitation-code>` for direct access or
`portp2p access request <invitation-code>` for approval access.

Do not confuse the normal private share code, public discovery code, private
invitation, request token, or approved grant. They are separate capabilities
with different exposure and revocation boundaries. There are no user accounts,
roles, payments, marketplace rankings, or persistent request database.

## ComfyUI And WebSocket Applications

ComfyUI normally uses port `8188`:

```sh
portp2p share 8188 --plain --expires 2h
```

On the connector:

```sh
portp2p connect <share-code> --plain
```

The user opens `http://127.0.0.1:8188`. HTTP, uploads, generated images, queue
events, and the progress WebSocket cross the same raw TCP tunnel. Do not add a
separate WebSocket proxy on either endpoint.

Verify more than the initial page:

- the interface loads without missing assets;
- a workflow can be queued;
- progress updates continue in real time;
- generated output can be viewed or downloaded;
- reconnecting the browser does not require a new share while the code remains
  valid.

If the page loads but live updates fail, investigate any reverse proxy in front
of the public relay, not the localhost tunnel.

## Proxies And Restricted Networks

`portp2p` supports standard `HTTP_PROXY`, `HTTPS_PROXY`, and `NO_PROXY`
variables. `PORTP2P_PROXY`, `--proxy`, or `proxy_url` applies one HTTP CONNECT
or SOCKS5 proxy to rendezvous and WSS relay traffic.

Example:

```sh
export HTTPS_PROXY=http://user:password@proxy.example.com:3128
export HTTP_PROXY=http://user:password@proxy.example.com:3128
export NO_PROXY=127.0.0.1,localhost
portp2p connect <share-code> --plain
```

SOCKS5:

```sh
export PORTP2P_PROXY=socks5://127.0.0.1:1080
portp2p connect <share-code> --plain
```

Safety and diagnosis rules:

- Prefer environment variables or a private config file over a credentialed
  `--proxy` argument.
- Do not print environment-variable values while checking whether they are set.
- Use `portp2p status --plain`; it reports proxy source without revealing the
  URL or credentials.
- Ensure `NO_PROXY` includes localhost when required by the user's environment.
- Native TCP and QUIC cannot traverse a conventional HTTP proxy.
- A public relay must advertise a WSS address, normally on TCP 443, for
  proxy-restricted clients.
- When proxy configuration and WSS are available, `connect` prefers the WSS
  relay before direct native transports.

Check whether proxy variables exist without printing their values:

```sh
test -n "${HTTPS_PROXY:-}" && printf 'HTTPS_PROXY is set\n'
test -n "${PORTP2P_PROXY:-}" && printf 'PORTP2P_PROXY is set\n'
```

## JSON Configuration

Use a JSON config file when persistent, repeatable settings are preferable to
environment variables:

```json
{
  "server_url": "https://relay.example.com",
  "log_level": "info",
  "identity_path": "/home/user/.config/portp2p/identity.key",
  "proxy_url": ""
}
```

Run with:

```sh
portp2p --config /path/to/portp2p.json status --plain
```

Supported variables:

| Variable | Flag | Purpose |
| --- | --- | --- |
| `PORTP2P_CONFIG` | `--config` | JSON config path |
| `PORTP2P_SERVER` | `--server` | Rendezvous URL |
| `PORTP2P_IDENTITY` | `--identity` | Persistent peer identity path |
| `PORTP2P_PROXY` | `--proxy` | HTTP CONNECT or SOCKS5 proxy URL |
| `PORTP2P_LOG_LEVEL` | `--log-level` | Logging verbosity |

If `proxy_url` contains credentials, protect the config file with user-only
permissions and never commit it.

## Identity Handling

The default identity lives under the operating system's user config directory.
A stable identity makes peer behavior predictable across runs.

- Keep the private-key file readable only by the owning account.
- For a service, keep the key on persistent storage owned by the service user.
- Back it up before moving infrastructure.
- Do not copy one private identity to unrelated peers.
- Do not delete the key as a generic troubleshooting step.
- If rotation is intentional, expect the Peer ID and every advertised relay
  multiaddr to change.

`portp2p status --plain` shows the identity path and effective configuration
without exposing private-key material.

Use `portp2p identity init` to initialize the configured identity explicitly,
`portp2p identity backup <destination>` to create a private backup, and
`portp2p identity restore <backup>` on a new installation. Backup and restore
never print key material and never overwrite an existing destination. The
backup itself is not encrypted and must be stored securely.

## Operate Infrastructure

Use combined server mode unless the deployment specifically needs rendezvous
and relay to run separately.

### Private-Network Deployment

```sh
portp2p server --plain \
  --listen 0.0.0.0:8080 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --identity /var/lib/portp2p/identity.key
```

Allow TCP `8080` and `4001` only from the intended networks. Plain HTTP is for
trusted private networks or local testing, not the public internet.

### Public HTTPS And WSS Deployment

The recommended shape is:

- HTTPS 443 to rendezvous on `127.0.0.1:8080`;
- WSS 443 to the libp2p WebSocket listener on `127.0.0.1:4002`;
- optional public native libp2p TCP 4001;
- one persistent identity shared by those listeners in the same server process.

Start once with the persistent identity and record the printed Peer ID. Then
configure public relay addresses containing that exact ID:

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

Keep the WSS address first. Clients obtain relay addresses through `/v1/info`,
so operators can change relay transport addresses without publishing new client
binaries.

Minimal Caddy routing:

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

Before reloading a reverse proxy, validate its configuration with that proxy's
native validation command. Do not expose internal port `4002` publicly.

### Production Limits

The server has finite defaults for control body size, rate limiting, active
sessions, peer addresses, relay reservations, circuits, duration, and bytes.
Keep those limits enabled.

For an explicit baseline:

```sh
portp2p server --plain \
  --listen 127.0.0.1:8080 \
  --trusted-proxy 127.0.0.1 \
  --p2p-listen /ip4/0.0.0.0/tcp/4001 \
  --rate-limit-requests 120 \
  --rate-limit-window 1m \
  --max-control-bytes 65536 \
  --max-sessions 10000 \
  --max-sessions-per-remote 16 \
  --max-addrs-per-share 32 \
  --max-discovery-listings 1000 \
  --max-discovery-listings-per-remote 4 \
  --relay-profile public-small \
  --identity /var/lib/portp2p/identity.key
```

Tune limits only from observed capacity and expected traffic. Do not set session
limits to zero or relay duration/data limits negative on public services.

## Operational Verification

### After Installation Or Update

```sh
portp2p version --plain
portp2p --help
portp2p status --plain
```

Confirm:

- the expected release version is installed;
- OS and architecture are correct;
- the server URL is expected;
- the identity path is persistent and private;
- proxy source is expected and credentials are not printed.

### After Starting Infrastructure

```sh
curl https://relay.example.com/healthz
curl https://relay.example.com/readyz
curl https://relay.example.com/metrics
curl https://relay.example.com/v1/info
```

Confirm:

- health and readiness return success;
- `/v1/info` includes `share-management-v1`;
- `/v1/info` publishes the intended relay multiaddrs;
- every advertised address contains the running relay Peer ID;
- the WSS address uses the public DNS name and TLS port;
- the plain internal WebSocket port is not publicly reachable;
- the native relay port is reachable when it is part of the design.

### End-To-End Verification

Use a harmless local target. Keep the actual share code out of logs and final
reports.

On the sharer:

```sh
portp2p share 3000 --plain --expires 10m
```

On the connector:

```sh
portp2p connect <share-code> --plain --port 9000 --verbose
curl -I http://127.0.0.1:9000/
```

Record only the sanitized connection path: `DIRECT` or `RELAY`. For a public
deployment, verify relay fallback separately with `--relay-only`. For a
proxy-dependent deployment, verify from the actual restricted network; a test
from the server itself is not equivalent.

## Automation Output

Use `--json` when another program consumes output:

```sh
portp2p status --json
portp2p version --json
```

Errors are also structured in JSON mode. Do not parse terminal UI output or
human-readable plain text when a JSON form exists.

Use `--plain` for logs and operator transcripts. Interactive terminal output is
intended for humans and may change presentation without changing behavior.

## Troubleshooting Decision Tree

### No Server Is Configured

1. Run `portp2p version --plain`.
2. Run `portp2p status --plain`.
3. Obtain the approved rendezvous URL.
4. Set `PORTP2P_SERVER` on both peers.
5. Do not substitute an unrelated public service.

### Share Fails Before Registration

1. Confirm the port number is correct.
2. Check `127.0.0.1:<port>` locally.
3. Confirm the application finished starting.
4. Increase `--target-check-timeout` for a slow service.
5. Use `--skip-target-check` only for an intentionally delayed target.

### Connector Cannot Listen

1. Check whether the target port is already occupied.
2. Choose a free `--port`.
3. Keep the default `127.0.0.1` bind.

### Resolve Fails

1. Confirm both peers use the same server URL.
2. Confirm the share process is still running.
3. Confirm the code has not expired.
4. Confirm the code was copied exactly without publishing it.
5. Check rendezvous health and readiness.

### Direct Dial Fails

1. Let the normal connection strategy attempt relay fallback.
2. Inspect sanitized `--verbose` output.
3. Query `/v1/info` and confirm relay addresses are present.
4. Run `connect --relay-only` to isolate the fallback path.
5. Do not assume port forwarding is required when relay works.

### Proxy Or WSS Fails

1. Run `portp2p status --plain` to confirm proxy source.
2. Confirm the proxy scheme is HTTP(S) CONNECT or SOCKS5.
3. Confirm localhost is handled correctly by `NO_PROXY`.
4. Confirm `/v1/info` publishes a `/tls/ws/` relay address.
5. Confirm the reverse proxy forwards WebSocket Upgrade requests to port 4002.
6. Confirm outbound TCP 443 is permitted from the restricted network.

### Browser Page Loads But Live Updates Fail

1. Verify the application works directly on the sharer.
2. Keep the tunnel open and reproduce the actual interactive action.
3. Check the browser's WebSocket request without exposing its share code.
4. Inspect the public relay reverse proxy's Upgrade routing.
5. Do not add a second application proxy to the endpoint clients.

### Registration Disappears After A Server Restart

A running share automatically re-registers without extending its original
expiry. Allow the configured retry interval, then resolve again. If recovery
does not occur, collect sanitized sharer output and server health status.

## Updating And Uninstalling

Update through the original package manager. Verify the version afterward.

macOS:

```sh
brew update
brew upgrade portp2p
```

Ubuntu/Debian:

```sh
sudo apt update
sudo apt install --only-upgrade portp2p
```

Fedora/RHEL-compatible:

```sh
sudo dnf upgrade portp2p
```

Package removal does not intentionally rotate the user identity. Before
deleting config directories or identity keys, explain that future installations
will receive a different Peer ID and ask for explicit approval.

## Reporting Issues

Collect:

```sh
portp2p version --plain
portp2p status --plain
```

Record:

- machine role;
- operating system and architecture;
- installation method;
- sanitized rendezvous hostname;
- direct or relay connection path;
- whether a proxy was involved;
- exact command error with secrets removed;
- expected behavior and observed behavior.

Never include:

- a live or expired share code;
- proxy URLs containing credentials;
- private identity keys;
- access tokens;
- full environment dumps;
- unrelated private addresses or application data.

Use [GitHub Issues](https://github.com/yousef-muc/portp2p/issues) for confirmed
bugs and focused feature requests.

## Agent Completion Report

At the end of an installation or operations task, report:

1. machine role and platform;
2. installed `portp2p` version;
3. configuration source used, without secret values;
4. commands or files changed;
5. verification performed and the observed result;
6. whether the path was direct, relayed, or not yet verified;
7. any remaining user action or operational risk.

Do not report a share code. Do not describe a service as production-ready when
only process startup or localhost health has been checked.
