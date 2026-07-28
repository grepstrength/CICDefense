#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- Base + desktop (same as before) ---
apt-get update
apt-get install -y curl wget gpg git apt-transport-https software-properties-common
apt-get install -y xfce4 xfce4-goodies xrdp

echo "xfce4-session" > /home/${admin_username}/.xsession
chown ${admin_username}:${admin_username} /home/${admin_username}/.xsession
adduser xrdp ssl-cert
systemctl enable xrdp
systemctl restart xrdp

# --- VS Code ---
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor > /usr/share/keyrings/microsoft.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    > /etc/apt/sources.list.d/vscode.list
apt-get update
apt-get install -y code

# --- Recon / OSINT (apt) ---
apt-get install -y nmap masscan dnsrecon amass whatweb

# --- Web app testing (apt) ---
apt-get install -y nikto gobuster ffuf wfuzz

# --- Python-based tools via pipx ---
apt-get install -y python3-venv pipx
export PIPX_HOME=/opt/pipx
export PIPX_BIN_DIR=/usr/local/bin
pipx install sqlmap || true
pipx install theHarvester || true

# --- Secrets scanning ---
# trufflehog (official installer)
curl -sSfL https://raw.githubusercontent.com/trufflesecurity/trufflehog/main/scripts/install.sh \
    | sh -s -- -b /usr/local/bin || true
# gitleaks (release binary)
GITLEAKS_VER="8.18.4"
wget -q "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VER}/gitleaks_${GITLEAKS_VER}_linux_x64.tar.gz" -O /tmp/gitleaks.tar.gz \
    && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks || true

# --- Traffic ---
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt-get install -y wireshark tshark
apt-get install -y mitmproxy

# --- OWASP ZAP (installed via snap) ---
apt-get install -y snapd
snap install zaproxy --classic || true

# --- Burp Community (downloaded, NOT installed) ---
BURP_DIR="/home/${admin_username}/Downloads"
mkdir -p "$BURP_DIR"
wget -q "https://portswigger.net/burp/releases/download?product=community&type=Linux" \
    -O "$BURP_DIR/burpsuite_community_linux.sh" || true
chown -R ${admin_username}:${admin_username} "$BURP_DIR"

# --- Ollama ---
curl -fsSL https://ollama.com/install.sh | sh

echo "Provisioning complete (notkali attacker)."