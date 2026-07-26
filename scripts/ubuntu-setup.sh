#!/bin/bash
set -euo pipefail # error failsafe 

export DEBIAN_FRONTEND=noninteractive

# --- Base packages ---
apt-get update
apt-get install -y \
    curl \
    wget \
    gpg \
    git \
    apt-transport-https \
    software-properties-common

# --- XFCE desktop + xrdp ---
apt-get install -y xfce4 xfce4-goodies xrdp

# tell xrdp to launch XFCE for the admin user
echo "xfce4-session" > /home/${admin_username}/.xsession
chown ${admin_username}:${admin_username} /home/${admin_username}/.xsession

# this is because xrdp needs read access to the TLS cert
adduser xrdp ssl-cert
systemctl enable xrdp
systemctl restart xrdp

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