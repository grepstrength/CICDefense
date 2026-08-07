#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- xrdp ---
# Kali's Azure marketplace image aleady comes with an offensive toolset and a desktop env.
# This is meant just to make the desktop reachable over Bastion host via RDP (port 3389)
apt-get update
apt-get install -y xrdp
adduser xrdp ssl-cert
systemctl enable xrdp
systemctl restart xrdp

echo "Provisioning complete (kali w/ xrdp ony)."