param(
  [Alias("y")]
  [switch]$Yes,
  [switch]$NonInteractive,
  [switch]$Doctor,
  [switch]$SkipOptionalTools,
  [switch]$SkipWinget,
  [switch]$SkipModules
)

$ErrorActionPreference = "Stop"
$ScriptName = Split-Path -Leaf $PSCommandPath
$IsWin = $env:OS -eq "Windows_NT"

if (-not $IsWin) {
  $bashInstaller = Join-Path $PSScriptRoot "install-zsh-setup.sh"
  if (-not (Test-Path $bashInstaller)) {
    throw "install-zsh-setup.sh was not found next to $ScriptName."
  }

  $args = @()
  if ($Yes) { $args += "--yes" }
  if ($NonInteractive) { $args += "--non-interactive" }
  if ($Doctor) { $args += "--doctor" }
  if ($SkipOptionalTools) { $args += "--skip-optional-tools" }

  & bash $bashInstaller @args
  exit $LASTEXITCODE
}

$NonInteractive = $NonInteractive -or -not [Environment]::UserInteractive
$ForceYes = $Yes -or $NonInteractive

$ConfigDir = Join-Path $HOME ".config\artur-powershell-setup"
$ManagedProfile = Join-Path $ConfigDir "profile.ps1"
$StateDir = Join-Path $HOME ".local\state\powershell"
$ManagedModuleDir = Join-Path $HOME ".local\share\powershell\Modules"
$WindowsTerminalSettings = @(
  (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
  (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json")
)
# PowerShell runs both the all-hosts and the current-host profile on every
# start. The loader lives only in the all-hosts profile so the managed profile
# runs once; older releases also put it into the current-host profile.
$ProfileTarget = $PROFILE.CurrentUserAllHosts
$LegacyProfileTargets = @($PROFILE.CurrentUserCurrentHost) | Where-Object { $_ -ne $ProfileTarget }

$WingetPackages = @(
  @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7" },
  @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
  @{ Id = "Git.Git"; Name = "Git" },
  @{ Id = "GitHub.cli"; Name = "GitHub CLI" },
  @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
  @{ Id = "Tailscale.Tailscale"; Name = "Tailscale" },
  @{ Id = "JanDeDobbeleer.OhMyPosh"; Name = "Oh My Posh" },
  @{ Id = "junegunn.fzf"; Name = "fzf" },
  @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
  @{ Id = "sharkdp.bat"; Name = "bat" },
  @{ Id = "ajeetdsouza.zoxide"; Name = "zoxide" },
  @{ Id = "Oven-sh.Bun"; Name = "bun" },
  @{ Id = "astral-sh.uv"; Name = "uv" }
)

$PowerShellModules = @(
  "PSReadLine",
  "Terminal-Icons",
  "posh-git",
  "PSFzf",
  "CompletionPredictor"
)

$SummaryInstalled = New-Object System.Collections.Generic.List[string]
$SummaryUpdated = New-Object System.Collections.Generic.List[string]
$SummarySkipped = New-Object System.Collections.Generic.List[string]
$SummaryWarnings = New-Object System.Collections.Generic.List[string]
$SummaryFailures = New-Object System.Collections.Generic.List[string]

function Write-Header {
  Write-Host ""
  Write-Host "Artur's PowerShell setup installer" -ForegroundColor Cyan
  Write-Host "========================================"
}

function Write-Step([string]$Number, [string]$Text) {
  Write-Host ""
  Write-Host "[$Number] $Text" -ForegroundColor Blue
}

function Write-Ok([string]$Text) {
  Write-Host "[ok] $Text" -ForegroundColor Green
}

function Write-Warn([string]$Text) {
  Write-Host "[warn] $Text" -ForegroundColor Yellow
  $SummaryWarnings.Add($Text) | Out-Null
}

function Test-Command([string]$Name) {
  return ($null -ne (Get-Command $Name -ErrorAction SilentlyContinue))
}

function Invoke-Check([string]$Label, [scriptblock]$Check) {
  try {
    if (& $Check) {
      Write-Ok $Label
      return $true
    }
  } catch {
  }

  Write-Host "[err] $Label" -ForegroundColor Red
  $SummaryFailures.Add($Label) | Out-Null
  return $false
}

function Confirm-Step([string]$Prompt, [bool]$DefaultYes = $true) {
  if ($ForceYes) {
    return $DefaultYes
  }

  $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
  $answer = Read-Host "$Prompt $suffix"
  if ([string]::IsNullOrWhiteSpace($answer)) {
    return $DefaultYes
  }

  return $answer -match "^[Yy]"
}

function Update-SessionPath {
  $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $env:Path = "$machinePath;$userPath"
}

function Install-WingetPackage([hashtable]$Package) {
  if ($SkipWinget) {
    $SummarySkipped.Add($Package.Name) | Out-Null
    return
  }

  if (-not (Test-Command "winget")) {
    Write-Warn "winget is not available. Skipping $($Package.Name)."
    $SummarySkipped.Add($Package.Name) | Out-Null
    return
  }

  Write-Host "Installing/updating $($Package.Name)"
  & winget upgrade --id $Package.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
  if ($LASTEXITCODE -eq 0) {
    $SummaryUpdated.Add($Package.Name) | Out-Null
    return
  }

  & winget install --id $Package.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Host
  if ($LASTEXITCODE -eq 0) {
    $SummaryInstalled.Add($Package.Name) | Out-Null
    return
  }

  $primaryCommand = switch ($Package.Id) {
    "Microsoft.PowerShell" { "pwsh" }
    "Microsoft.WindowsTerminal" { "wt" }
    "Git.Git" { "git" }
    "GitHub.cli" { "gh" }
    "Microsoft.VisualStudioCode" { "code" }
    "Tailscale.Tailscale" { "tailscale" }
    "JanDeDobbeleer.OhMyPosh" { "oh-my-posh" }
    "junegunn.fzf" { "fzf" }
    "BurntSushi.ripgrep.MSVC" { "rg" }
    "sharkdp.bat" { "bat" }
    "ajeetdsouza.zoxide" { "zoxide" }
    "Oven-sh.Bun" { "bun" }
    "astral-sh.uv" { "uv" }
    default { $null }
  }

  Update-SessionPath
  if ($primaryCommand -and (Test-Command $primaryCommand)) {
    Write-Ok "$($Package.Name) is already available"
    $SummarySkipped.Add($Package.Name) | Out-Null
    return
  }

  Write-Warn "$($Package.Name) could not be installed or updated by winget."
  $SummarySkipped.Add($Package.Name) | Out-Null
}

function Install-Modules {
  if ($SkipModules) {
    foreach ($module in $PowerShellModules) {
      $SummarySkipped.Add($module) | Out-Null
    }
    return
  }

  if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Scope CurrentUser -Force | Out-Null
  }

  $moduleRoots = @(
    $ManagedModuleDir,
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules"),
    (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell\Modules")
  ) | Select-Object -Unique
  foreach ($moduleRoot in $moduleRoots) {
    try {
      [System.IO.Directory]::CreateDirectory($moduleRoot) | Out-Null
    } catch {
      Write-Warn "Could not create module directory ${moduleRoot}: $($_.Exception.Message)"
    }
  }

  Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

  foreach ($module in $PowerShellModules) {
    try {
      if (Get-Module -ListAvailable -Name $module) {
        try {
          Update-Module -Name $module -Force -ErrorAction Stop
        } catch {
          Save-Module -Name $module -Path $ManagedModuleDir -Force -ErrorAction Stop
        }
        $SummaryUpdated.Add($module) | Out-Null
      } else {
        try {
          Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        } catch {
          Save-Module -Name $module -Path $ManagedModuleDir -Force -ErrorAction Stop
        }
        $SummaryInstalled.Add($module) | Out-Null
      }
      Write-Ok "$module is installed"
    } catch {
      Write-Warn "$module could not be installed or updated: $($_.Exception.Message)"
      $SummarySkipped.Add($module) | Out-Null
    }
  }
}

function Write-ManagedProfile {
  New-Item -ItemType Directory -Force -Path $ConfigDir, $StateDir | Out-Null

  @'
# Managed by Artur's zsh-setup installer for Windows PowerShell.
# This file is sourced from the user's PowerShell profile and can be regenerated safely.

$global:ArturPowerShellSetup = @{
  ConfigDir = Join-Path $HOME ".config\artur-powershell-setup"
  StateDir = Join-Path $HOME ".local\state\powershell"
}

function Add-PathIfExists {
  param([string]$Path)
  if ((Test-Path $Path) -and (($env:Path -split ';') -notcontains $Path)) {
    $env:Path = "$Path;$env:Path"
  }
}

Add-PathIfExists "$HOME\.local\bin"
Add-PathIfExists "$HOME\.bun\bin"
Add-PathIfExists "$HOME\AppData\Roaming\npm"
Add-PathIfExists "$HOME\AppData\Local\Programs\Ollama"
Add-PathIfExists "$HOME\.lmstudio\bin"
Add-PathIfExists "$HOME\AppData\Local\Programs\Antigravity\bin"

$managedModuleDir = Join-Path $HOME ".local\share\powershell\Modules"
if (Test-Path $managedModuleDir) {
  $env:PSModulePath = "$managedModuleDir;$env:PSModulePath"
}

$env:EDITOR = if ($env:EDITOR) { $env:EDITOR } else { "code --wait" }
$env:BAT_THEME = if ($env:BAT_THEME) { $env:BAT_THEME } else { "TwoDark" }
$env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border --info=inline"

# Import-Module only looks up the named module. Get-Module -ListAvailable reads
# every installed module manifest and was called once per module on each start.
Import-Module PSReadLine -ErrorAction SilentlyContinue
if (Get-Module PSReadLine) {
  Set-PSReadLineOption -EditMode Windows
  if (-not [Console]::IsOutputRedirected) {
    try {
      Set-PSReadLineOption -PredictionSource HistoryAndPlugin
      Set-PSReadLineOption -PredictionViewStyle ListView
    } catch {
      Set-PSReadLineOption -PredictionSource History
    }
  }
  Set-PSReadLineOption -HistorySavePath (Join-Path $global:ArturPowerShellSetup.StateDir "history.txt")
  Set-PSReadLineOption -HistoryNoDuplicates
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key Ctrl+Spacebar -Function AcceptSuggestion
}

Import-Module CompletionPredictor, Terminal-Icons, posh-git, PSFzf -ErrorAction SilentlyContinue

if (Get-Module PSFzf) {
  Set-PsFzfOption -PSReadlineChordProvider "Ctrl+f" -PSReadlineChordReverseHistory "Ctrl+r"
}

# Shell integration scripts only change when the tool is updated. Generate them
# once per tool version instead of starting the tool on every shell start.
function Get-ArturShellScript {
  param([string]$Name, [string[]]$Arguments)

  $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $command) { return }

  $cacheDir = Join-Path $global:ArturPowerShellSetup.StateDir "shell-scripts"
  $cache = Join-Path $cacheDir "$Name-$($Arguments -join '-').ps1"
  $cacheItem = Get-Item -LiteralPath $cache -ErrorAction SilentlyContinue
  if (-not $cacheItem -or $cacheItem.LastWriteTimeUtc -lt (Get-Item -LiteralPath $command.Source).LastWriteTimeUtc) {
    $script = & $command.Source @Arguments | Out-String
    if ($LASTEXITCODE -ne 0 -or -not $script.Trim()) { return }
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    Set-Content -LiteralPath $cache -Value $script -Encoding UTF8
  }
  $cache
}

# Dot-source at script level: the scripts define helpers their completers call later.
foreach ($shellScript in @(
  @{ Name = "zoxide"; Arguments = @("init", "powershell", "--cmd", "j") },
  @{ Name = "gh"; Arguments = @("completion", "-s", "powershell") },
  @{ Name = "uv"; Arguments = @("generate-shell-completion", "powershell") },
  @{ Name = "uvx"; Arguments = @("--generate-shell-completion", "powershell") }
)) {
  $shellScriptPath = Get-ArturShellScript @shellScript
  if ($shellScriptPath) { . $shellScriptPath }
}
Remove-Variable shellScript, shellScriptPath -ErrorAction SilentlyContinue

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
  $themeCandidates = @(
    "$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json",
    "$env:POSH_THEMES_PATH\paradox.omp.json",
    "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json"
  )
  $theme = $themeCandidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if ($theme) {
    oh-my-posh init pwsh --config $theme | Invoke-Expression
  } else {
    oh-my-posh init pwsh | Invoke-Expression
  }
}

function take {
  param([Parameter(Mandatory)][string]$Path)
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
  Set-Location $Path
}

function mkcd { take @args }
function reload { . $PROFILE }

Set-Alias d docker
Set-Alias g git
Set-Alias grep rg
Set-Alias vimdiff nvim -ErrorAction SilentlyContinue

function dc { docker compose @args }
function ni { npm install @args }
function nr { npm run @args }
function nrd { npm run dev @args }
function ns { npm start @args }
function ys { yarn start @args }
function bi { bun install @args }
function br { bun run @args }
function brd { bun run dev @args }
function bs { bun start @args }
function bx { bunx @args }
function ba { bun add @args }
function bad { bun add --dev @args }
function uvi { uv pip install @args }
function uvr { uv pip uninstall @args }
function uvs { uv pip sync @args }
function uvc { uv pip compile @args }
function uvv { uv venv @args }
function art { php artisan @args }
function sail { ./vendor/bin/sail @args }
function rgi { rg --ignore-case @args }

if (Get-Command bat -ErrorAction SilentlyContinue) {
  Remove-Item Alias:cat -Force -ErrorAction SilentlyContinue
  function cat { bat @args }
}

Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
  param($wordToComplete, $commandAst, $cursorPosition)
  winget complete --word="$wordToComplete" --commandline "$commandAst" --position $cursorPosition | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new($_, $_, "ParameterValue", $_)
  }
}
'@ | Set-Content -Path $ManagedProfile -Encoding UTF8

  Write-Ok "Managed PowerShell profile written to $ManagedProfile"
}

function Remove-ProfileLoader([string]$ProfilePath) {
  $markerStart = "# >>> artur-powershell-setup >>>"
  $markerEnd = "# <<< artur-powershell-setup <<<"

  if (-not (Test-Path $ProfilePath)) { return }
  try {
    $existing = Get-Content -Raw -Path $ProfilePath
    if (-not $existing -or $existing -notmatch [regex]::Escape($markerStart)) { return }
    $cleaned = [regex]::Replace($existing, "(?s)$([regex]::Escape($markerStart)).*?$([regex]::Escape($markerEnd))\r?\n?", "")
    Set-Content -Path $ProfilePath -Value $cleaned -Encoding UTF8 -NoNewline
    Write-Ok "Removed duplicate profile loader from $ProfilePath"
  } catch {
    Write-Warn "Could not clean up ${ProfilePath}: $($_.Exception.Message)"
  }
}

function Update-ProfileLoader([string]$ProfilePath) {
  $markerStart = "# >>> artur-powershell-setup >>>"
  $markerEnd = "# <<< artur-powershell-setup <<<"
  $loader = @"
$markerStart
`$arturProfile = Join-Path `$HOME ".config\artur-powershell-setup\profile.ps1"
if (Test-Path `$arturProfile) { . `$arturProfile }
$markerEnd
"@

  try {
    $dir = Split-Path -Parent $ProfilePath
    [System.IO.Directory]::CreateDirectory($dir) | Out-Null

    $existing = if (Test-Path $ProfilePath) { Get-Content -Raw -Path $ProfilePath } else { "" }
    if ($existing -and $existing -notmatch [regex]::Escape($markerStart)) {
      $backup = "$ProfilePath.backup.$(Get-Date -Format yyyyMMdd_HHmmss)"
      Copy-Item -Path $ProfilePath -Destination $backup
      Write-Ok "Backed up existing profile to $backup"
    }

    $cleaned = [regex]::Replace($existing, "(?s)$([regex]::Escape($markerStart)).*?$([regex]::Escape($markerEnd))\r?\n?", "")
    "$loader`r`n$cleaned" | Set-Content -Path $ProfilePath -Encoding UTF8
    Write-Ok "Profile loader updated: $ProfilePath"
  } catch {
    Write-Warn "Could not update profile loader at ${ProfilePath}: $($_.Exception.Message)"
  }
}

function Update-WindowsTerminalProfile {
  $settingsPath = $WindowsTerminalSettings | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $settingsPath) {
    Write-Warn "Windows Terminal settings.json was not found. Skipping terminal profile setup."
    return
  }

  try {
    $json = Get-Content -Raw -Path $settingsPath | ConvertFrom-Json
    if (-not $json.profiles) {
      $json | Add-Member -MemberType NoteProperty -Name profiles -Value ([pscustomobject]@{ list = @() })
    }
    if (-not $json.profiles.list) {
      $json.profiles | Add-Member -MemberType NoteProperty -Name list -Value @()
    }

    $profileName = "Artur PowerShell"
    $commandLine = "pwsh.exe -NoExit -ExecutionPolicy Bypass -Command `"& '$ManagedProfile'`""
    $existing = $json.profiles.list | Where-Object { $_.name -eq $profileName } | Select-Object -First 1

    if ($existing) {
      $existing.commandline = $commandLine
      $existing.startingDirectory = "%USERPROFILE%"
      $existing.hidden = $false
    } else {
      $newProfile = [pscustomobject]@{
        guid = "{$([guid]::NewGuid().ToString())}"
        name = $profileName
        commandline = $commandLine
        startingDirectory = "%USERPROFILE%"
        hidden = $false
      }
      $json.profiles.list = @($json.profiles.list) + $newProfile
    }

    $backup = "$settingsPath.backup.$(Get-Date -Format yyyyMMdd_HHmmss)"
    Copy-Item -Path $settingsPath -Destination $backup
    $json | ConvertTo-Json -Depth 100 | Set-Content -Path $settingsPath -Encoding UTF8
    Write-Ok "Windows Terminal profile '$profileName' configured"
  } catch {
    Write-Warn "Could not update Windows Terminal settings: $($_.Exception.Message)"
  }
}

function Invoke-Doctor {
  Write-Step "4" "Verifying installation"
  if (Test-Path $ManagedModuleDir) {
    $env:PSModulePath = "$ManagedModuleDir;$env:PSModulePath"
  }

  Invoke-Check "PowerShell is available" { $PSVersionTable.PSVersion -or (Test-Command "pwsh") -or (Test-Command "powershell.exe") } | Out-Null
  Invoke-Check "git is available" { Test-Command "git" } | Out-Null
  Invoke-Check "gh is available" { Test-Command "gh" } | Out-Null
  Invoke-Check "VS Code is available" { Test-Command "code" } | Out-Null
  Invoke-Check "Tailscale is available" { Test-Command "tailscale" } | Out-Null
  Invoke-Check "oh-my-posh is available" { Test-Command "oh-my-posh" } | Out-Null
  Invoke-Check "fzf is available" { Test-Command "fzf" } | Out-Null
  Invoke-Check "ripgrep is available" { Test-Command "rg" } | Out-Null
  Invoke-Check "bat is available" { Test-Command "bat" } | Out-Null
  Invoke-Check "zoxide is available" { Test-Command "zoxide" } | Out-Null
  Invoke-Check "bun is available" { Test-Command "bun" } | Out-Null
  Invoke-Check "uv is available" { Test-Command "uv" } | Out-Null
  Invoke-Check "managed profile exists" { Test-Path $ManagedProfile } | Out-Null
  Invoke-Check "managed profile parses" { $null = [scriptblock]::Create((Get-Content -Raw $ManagedProfile)); $true } | Out-Null
  Invoke-Check "managed profile is loaded once" {
    -not ($LegacyProfileTargets | Where-Object { (Test-Path $_) -and (Select-String -Path $_ -SimpleMatch "# >>> artur-powershell-setup >>>" -Quiet) })
  } | Out-Null

  foreach ($module in $PowerShellModules) {
    Invoke-Check "$module module is available" { Get-Module -ListAvailable -Name $module } | Out-Null
  }
}

function Write-Summary {
  Write-Host ""
  Write-Host "Summary" -ForegroundColor Cyan
  Write-Host "========================================"

  if ($SummaryInstalled.Count) {
    Write-Host "Installed:"
    $SummaryInstalled | ForEach-Object { Write-Host "  - $_" }
  }
  if ($SummaryUpdated.Count) {
    Write-Host "Updated:"
    $SummaryUpdated | ForEach-Object { Write-Host "  - $_" }
  }
  if ($SummarySkipped.Count) {
    Write-Host "Skipped:"
    $SummarySkipped | ForEach-Object { Write-Host "  - $_" }
  }
  if ($SummaryWarnings.Count) {
    Write-Host "Warnings:"
    $SummaryWarnings | ForEach-Object { Write-Host "  - $_" }
  }
  if ($SummaryFailures.Count) {
    Write-Host "Failed checks:"
    $SummaryFailures | ForEach-Object { Write-Host "  - $_" }
  }

  Write-Host ""
  Write-Host "Managed profile: $ManagedProfile"
  Write-Host "Next steps:"
  Write-Host "  1. Open a new Windows Terminal tab."
  Write-Host "  2. Re-run checks anytime with: pwsh -ExecutionPolicy Bypass -File .\install.ps1 -Doctor"
}

Write-Header
Write-Host "Running as : $env:USERNAME"
Write-Host "Home       : $HOME"

Update-SessionPath

if ($Doctor) {
  Invoke-Doctor
  Write-Summary
  if ($SummaryFailures.Count) { exit 1 }
  exit 0
}

Write-Step "1" "Installing Windows command-line tools"
if ($SkipOptionalTools) {
  $WingetPackages = $WingetPackages | Where-Object { $_.Id -notin @("Oven-sh.Bun", "astral-sh.uv") }
}
foreach ($package in $WingetPackages) {
  if (Confirm-Step "Install or update $($package.Name)?" $true) {
    Install-WingetPackage $package
  } else {
    $SummarySkipped.Add($package.Name) | Out-Null
  }
}

Update-SessionPath

Write-Step "2" "Installing PowerShell UX modules"
Install-Modules

Write-Step "3" "Writing PowerShell configuration"
Write-ManagedProfile
Update-ProfileLoader $ProfileTarget
foreach ($target in $LegacyProfileTargets) {
  Remove-ProfileLoader $target
}
Update-WindowsTerminalProfile

Update-SessionPath
Invoke-Doctor
Write-Summary

if ($SummaryFailures.Count) { exit 1 }
exit 0
