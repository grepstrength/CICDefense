#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# --- Base packages ---
apt-get update
apt-get install -y \
    curl wget gpg git apt-transport-https software-properties-common

# --- XFCE desktop + xrdp ---
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

# --- Ollama ---
curl -fsSL https://ollama.com/install.sh | sh

# --- Detection tooling (inline: fast + critical) ---
apt-get install -y auditd audispd-plugins
cat > /etc/audit/rules.d/cicdefense.rules <<'EOF'
# Watch for execution and privilege changes
-w /usr/bin -p x -k exec_usr_bin
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k priv_esc
-a always,exit -F arch=b64 -S execve -k exec
EOF
augenrules --load || true
systemctl enable auditd
systemctl restart auditd

# Wireshark + mitmproxy (non-interactive)
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
apt-get install -y wireshark tshark mitmproxy

# --- Build toolchains (inline: light) ---
apt-get install -y build-essential python3-pip python3-venv

# --- Persist admin user for the backgrounded script to read ---
echo "${admin_username}" > /etc/cicdefense-admin-user

# --- Detection + heavy toolchains (backgrounded: slow + non-critical) ---
# systemd one-shot so the extension returns fast and a slow/flaky
# install can't time out the whole apply.
cat > /usr/local/sbin/cicdefense-detection-install.sh <<'EOF'
#!/bin/bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
LOG=/var/log/cicdefense-detection-install.log
exec >>"$LOG" 2>&1
echo "=== background install started: $(date) ==="

ADMIN_USER="$(cat /etc/cicdefense-admin-user)"

# --- osquery ---
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.osquery.io/deb/pubkey.gpg \
    | gpg --dearmor -o /etc/apt/keyrings/osquery.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/osquery.gpg] https://pkg.osquery.io/deb deb main" \
    > /etc/apt/sources.list.d/osquery.list
apt-get update && apt-get install -y osquery

# --- Syft, Grype, Trivy ---
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh  | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
curl -sSfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# --- Docker CE ---
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
usermod -aG docker "$ADMIN_USER"

# --- Node.js LTS + npm ---
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get install -y nodejs
npm install -g @socketsecurity/cli || echo "socket cli install failed, continuing"

# --- Java JDK + Maven ---
apt-get install -y default-jdk maven

# --- .NET SDK ---
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/ms-prod.deb
dpkg -i /tmp/ms-prod.deb
apt-get update && apt-get install -y dotnet-sdk-8.0

# --- Go ---
GO_VER="1.23.4"
curl -fsSL "https://go.dev/dl/go$${GO_VER}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

# --- Rust (system-wide) ---
export RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/rust
curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
echo 'export PATH=$PATH:/opt/rust/bin' > /etc/profile.d/rust.sh

echo "=== background install finished: $(date) ==="
EOF
chmod +x /usr/local/sbin/cicdefense-detection-install.sh

cat > /etc/systemd/system/cicdefense-detection.service <<'EOF'
[Unit]
Description=CICDefense background detection + toolchain install
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/cicdefense-detection-install.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable cicdefense-detection.service
systemctl start --no-block cicdefense-detection.service

echo "Provisioning complete (ubuntu runner + detection + toolchains)."