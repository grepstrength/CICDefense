#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# --- Refresh keyring first (because Kali's repo signing key has expired more than once) ---
apt-get update || true
apt-get install -y --allow-unauthenticated kali-archive-keyring || true
apt-get update

# --- Base packages ---
apt-get install -y \
    curl \
    wget \
    gpg \
    git \
    apt-transport-https

# --- XFCE desktop + xrdp ---
apt-get install -y kali-desktop-xfce xrdp

echo "xfce4-session" > /home/${admin_username}/.xsession
chown ${admin_username}:${admin_username} /home/${admin_username}/.xsession

adduser xrdp ssl-cert
systemctl enable xrdp
systemctl restart xrdp

# --- Security tooling installation... just in case ---
apt-get install -y \
    kali-tools-information-gathering \
    kali-tools-web

# --- VS Code installation ---
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /usr/share/keyrings/microsoft.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list

apt-get update
apt-get install -y code

# --- Ollama installation ---
curl -fsSL https://ollama.com/install.sh | sh

echo "Provisioning complete."