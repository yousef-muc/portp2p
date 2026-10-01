#!/usr/bin/env sh
set -eu

BASE_URL="${PORTP2P_REPO_BASE_URL:-https://yousef-muc.github.io/portp2p}"

if command -v apt-get >/dev/null 2>&1; then
  sudo install -d -m 0755 /usr/share/keyrings
  curl -fsSL "${BASE_URL}/apt/gpg/portp2p.gpg" | sudo tee /usr/share/keyrings/portp2p-archive-keyring.gpg >/dev/null
  arch="$(dpkg --print-architecture)"
  echo "deb [arch=${arch} signed-by=/usr/share/keyrings/portp2p-archive-keyring.gpg] ${BASE_URL}/apt stable main" | sudo tee /etc/apt/sources.list.d/portp2p.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y portp2p
  exit 0
fi

if command -v dnf >/dev/null 2>&1; then
  sudo curl -fsSL "${BASE_URL}/rpm/portp2p.repo" -o /etc/yum.repos.d/portp2p.repo
  sudo dnf install -y portp2p
  exit 0
fi

if command -v yum >/dev/null 2>&1; then
  sudo curl -fsSL "${BASE_URL}/rpm/portp2p.repo" -o /etc/yum.repos.d/portp2p.repo
  sudo yum install -y portp2p
  exit 0
fi

echo "Unsupported Linux package manager. Install the .deb or .rpm package from the GitHub release." >&2
exit 1
