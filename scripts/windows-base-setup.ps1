$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # speeds up Invoke-WebRequest massively

[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.SecurityProtocolType]::Tls12

$tmp = "$env:TEMP\provision"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# --- git ---
$gitUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
$gitExe = "$tmp\git-install.exe"
Invoke-WebRequest -Uri $gitUrl -OutFile $gitExe
Start-Process -FilePath $gitExe -ArgumentList "/VERYSILENT /NORESTART" -Wait

# --- VS Code (system installer) ---
$vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64/stable"
$vscodeExe = "$tmp\vscode-install.exe"
Invoke-WebRequest -Uri $vscodeUrl -OutFile $vscodeExe
Start-Process -FilePath $vscodeExe -ArgumentList "/VERYSILENT /NORESTART /MERGETASKS=!runcode" -Wait

# --- Ollama ---
$ollamaUrl = "https://ollama.com/download/OllamaSetup.exe"
$ollamaExe = "$tmp\ollama-install.exe"
Invoke-WebRequest -Uri $ollamaUrl -OutFile $ollamaExe
Start-Process -FilePath $ollamaExe -ArgumentList "/VERYSILENT" -Wait

# --- Disable IE Enhanced Security (guarded) ---
$adminKey = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
if (Test-Path $adminKey) {
    Set-ItemProperty -Path $adminKey -Name 'IsInstalled' -Value 0 -Force
}
Write-Output "Provisioning complete (windows runner)."