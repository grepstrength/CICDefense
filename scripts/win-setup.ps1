# Stop on any error so the extension reports a failure
$ErrorActionPreference = "Stop"

# --- install Chocolatey ---
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.SecurityProtocolType]::Tls12

Invoke-Expression (
    (New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'
    )
)

# --- install tools ---
$packages = @(
    'git',
    'vscode',
    'notepadplusplus',
    'googlechrome',
    'ollama'
)

foreach ($pkg in $packages) {
    choco install $pkg -y --no-progress
}

# --- disable IE Enhanced Security (to make Chrome usable) ---
$adminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
$userKey  = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
Set-ItemProperty -Path $adminKey -Name 'IsInstalled' -Value 0 -Force
Set-ItemProperty -Path $userKey  -Name 'IsInstalled' -Value 0 -Force