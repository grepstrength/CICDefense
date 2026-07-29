$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # speeds up Invoke-WebRequest massively

[System.Net.ServicePointManager]::SecurityProtocol = `
    [System.Net.SecurityProtocolType]::Tls12

$tmp = "$env:TEMP\provision"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

# --- Detection tooling ---
$tools = "C:\Tools"
New-Item -ItemType Directory -Force -Path $tools | Out-Null

# Sysmon + SwiftOnSecurity config
$sysmonZip = "$tmp\Sysmon.zip"
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile $sysmonZip
Expand-Archive -Path $sysmonZip -DestinationPath "$tools\Sysmon" -Force
Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" `
    -OutFile "$tools\Sysmon\sysmonconfig.xml"
Start-Process -FilePath "$tools\Sysmon\Sysmon64.exe" `
    -ArgumentList "-accepteula -i `"$tools\Sysmon\sysmonconfig.xml`"" -Wait

# Sysinternals: Procmon + Autoruns
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/ProcessMonitor.zip" -OutFile "$tmp\Procmon.zip"
Expand-Archive -Path "$tmp\Procmon.zip" -DestinationPath "$tools\Procmon" -Force
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Autoruns.zip" -OutFile "$tmp\Autoruns.zip"
Expand-Archive -Path "$tmp\Autoruns.zip" -DestinationPath "$tools\Autoruns" -Force

# Regshot (non-fatal — SourceForge redirect is unreliable)
try {
    Invoke-WebRequest `
        -Uri "https://sourceforge.net/projects/regshot/files/latest/download" `
        -OutFile "$tmp\Regshot.zip"
    Expand-Archive -Path "$tmp\Regshot.zip" -DestinationPath "$tools\Regshot" -Force
} catch {
    Write-Output "Regshot download failed, skipping: $_"
}

# --- .NET SDK 8.0 (official dotnet-install script) ---
$dotnetScript = "$tmp\dotnet-install.ps1"
Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $dotnetScript
& $dotnetScript -Channel 8.0 -InstallDir "C:\Program Files\dotnet"
# Add dotnet to system PATH
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($machinePath -notlike "*C:\Program Files\dotnet*") {
    [Environment]::SetEnvironmentVariable(
        "Path", "$machinePath;C:\Program Files\dotnet", "Machine")
}

# --- Node.js LTS (MSI, silent) ---
$nodeUrl = "https://nodejs.org/dist/v22.12.0/node-v22.12.0-x64.msi"
$nodeMsi = "$tmp\node.msi"
Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeMsi
Start-Process msiexec.exe -ArgumentList "/i `"$nodeMsi`" /quiet /norestart" -Wait

Write-Output "Provisioning complete (windows runner)."