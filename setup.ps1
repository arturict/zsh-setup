$ErrorActionPreference = 'Stop'
$Repo = 'https://github.com/arturict/zsh-setup.git'
$InstallDir = Join-Path $env:USERPROFILE '.devhub'

if ($env:OS -ne 'Windows_NT') {
    throw 'Use setup.sh on Ubuntu or WSL.'
}

Write-Host 'devhub Windows bootstrap' -ForegroundColor Cyan
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget fehlt. Installiere zuerst den Microsoft App Installer.'
    }
    winget install --id Git.Git --exact --accept-package-agreements --accept-source-agreements --silent
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

if (Test-Path (Join-Path $InstallDir '.git')) {
    git -C $InstallDir pull --ff-only
} else {
    if (Test-Path $InstallDir) {
        Rename-Item $InstallDir "$InstallDir.backup.$(Get-Date -Format yyyyMMddHHmmss)"
    }
    git clone --depth=1 $Repo $InstallDir
}

# The repository's full Windows installer manages winget packages, PowerShell
# modules, profiles, backups, terminal settings and its own doctor checks.
& (Join-Path $InstallDir 'install.ps1') -Yes

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $distros = @(wsl --list --quiet 2>$null) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if (-not $distros) {
        Write-Host 'Installiere Ubuntu in WSL. Windows kann dafür Administratorrechte oder einen Neustart verlangen.' -ForegroundColor Yellow
        wsl --install -d Ubuntu
    }
} else {
    Write-Warning 'WSL ist nicht verfügbar. Aktiviere es als Administrator mit: wsl --install -d Ubuntu'
}

$BinDir = Join-Path $env:USERPROFILE '.local\bin'
New-Item -ItemType Directory -Force $BinDir | Out-Null
Copy-Item (Join-Path $InstallDir 'bin\devhub.ps1') (Join-Path $BinDir 'devhub.ps1') -Force

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($userPath -split ';') -notcontains $BinDir) {
    [Environment]::SetEnvironmentVariable('Path', "$BinDir;$userPath", 'User')
}

$profileDir = Split-Path $PROFILE.CurrentUserAllHosts
New-Item -ItemType Directory -Force $profileDir | Out-Null
if (-not (Test-Path $PROFILE.CurrentUserAllHosts)) {
    New-Item -ItemType File $PROFILE.CurrentUserAllHosts | Out-Null
}
if (-not (Select-String -Path $PROFILE.CurrentUserAllHosts -SimpleMatch '# devhub command' -Quiet)) {
    Add-Content $PROFILE.CurrentUserAllHosts "`n# devhub command`nfunction devhub { & `"$BinDir\devhub.ps1`" @args }"
}

Write-Host "`nWindows und devhub sind eingerichtet." -ForegroundColor Green
Write-Host 'Öffne ein neues Terminal und starte: devhub'
Write-Host 'Für Linux-Development richtest du danach devhub innerhalb von Ubuntu/WSL ein.'
