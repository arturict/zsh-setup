param([ValidateSet('dashboard','doctor','tmux','tips','auth','help')][string]$Command = 'dashboard')

$ErrorActionPreference = 'Stop'
$Version = '1.0.0'

function Header($Title) {
    Clear-Host
    Write-Host " devhub $Version " -NoNewline -ForegroundColor Black -BackgroundColor Cyan
    Write-Host "  $env:COMPUTERNAME · windows · $((Get-Location).Path)" -ForegroundColor DarkGray
    Write-Host ('─' * 72)
    Write-Host "`n$Title`n" -ForegroundColor Magenta
}

function Doctor {
    Header 'Systemcheck'
    foreach ($tool in 'git','gh','wt','wsl','code') {
        $found = Get-Command $tool -ErrorAction SilentlyContinue
        if ($found) { Write-Host "  ● $($tool.PadRight(12)) $($found.Source)" -ForegroundColor Green }
        else { Write-Host "  ○ $($tool.PadRight(12)) nicht installiert" -ForegroundColor Yellow }
    }
    Write-Host "`nLinux-Entwicklung läuft innerhalb von WSL. Starte sie mit: wsl" -ForegroundColor Cyan
}

function TmuxHelp {
    Header 'tmux läuft innerhalb von WSL oder auf dem Remote-Host'
    @(
        @('t','Projekt-Session öffnen oder erstellen'),
        @('Ctrl-a s','Sessions und Fenster auswählen'),
        @('Ctrl-a c','Neues Fenster'),
        @('Ctrl-a | / -','Pane seitlich oder unten öffnen'),
        @('Ctrl-a d','Trennen; Prozesse laufen weiter')
    ) | ForEach-Object { Write-Host ('  {0,-18} {1}' -f $_[0], $_[1]) }
}

function AuthHelp {
    Header 'Auth-Zentrale'
    Write-Host '  GitHub CLI:  gh auth login'
    Write-Host '  Danach in WSL: devhub auth'
    Write-Host "`nTokens werden niemals im Repository gespeichert." -ForegroundColor Yellow
}

function Tips {
    Header 'Windows + WSL Workflow'
    Write-Host '  wt              Windows Terminal öffnen'
    Write-Host '  wsl             Ubuntu-Entwicklungsumgebung öffnen'
    Write-Host '  wsl --shutdown  WSL vollständig neu starten'
    Write-Host '  code .          Aktuelles Verzeichnis in VS Code öffnen'
    Write-Host '  ssh x1          Über Tailscale mit x1 verbinden'
}

function Dashboard {
    while ($true) {
        Header 'Dein Development Workspace'
        Write-Host '  1  System prüfen'
        Write-Host '  2  tmux lernen'
        Write-Host '  3  Windows/WSL Commands'
        Write-Host '  4  Auth-Zentrale'
        Write-Host '  q  Beenden'
        switch (Read-Host "`nAuswahl") {
            '1' { Doctor; Read-Host "`nEnter zum Fortfahren" }
            '2' { TmuxHelp; Read-Host "`nEnter zum Fortfahren" }
            '3' { Tips; Read-Host "`nEnter zum Fortfahren" }
            '4' { AuthHelp; Read-Host "`nEnter zum Fortfahren" }
            'q' { Clear-Host; return }
        }
    }
}

switch ($Command) {
    'dashboard' { Dashboard }
    'doctor' { Doctor }
    'tmux' { TmuxHelp }
    'tips' { Tips }
    'auth' { AuthHelp }
    'help' { Write-Host 'devhub [dashboard|doctor|tmux|tips|auth]' }
}
