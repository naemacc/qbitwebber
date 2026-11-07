# install-qbitopen.ps1
# One-time setup so the new "open folder" button in the web UI can open Windows Explorer.
# No admin rights needed (registers for the current user only).
#
#   Install:    right-click > Run with PowerShell
#               (or: powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1)
#   Uninstall:  powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$dir  = Join-Path $env:LOCALAPPDATA 'qbitopen'
$root = 'HKCU:\Software\Classes\qbitopen'

if ($Uninstall) {
    if (Test-Path $root) { Remove-Item -Path $root -Recurse -Force }
    if (Test-Path $dir)  { Remove-Item -Path $dir  -Recurse -Force }
    Write-Host 'Uninstalled.'
    Read-Host 'Press Enter to close'
    exit 0
}

New-Item -ItemType Directory -Force -Path $dir | Out-Null

# ---------------------------------------------------------------------------
# handler.ps1 - receives  qbitopen:<url-encoded path>  and opens Explorer
# ---------------------------------------------------------------------------
$handler = @'
param([string]$Url)

# ---- Optional path mapping --------------------------------------------------
# Only needed if qBittorrent does NOT run on this PC (Docker, NAS, WSL, remote
# box), so the paths it reports do not exist on Windows. First match wins.
# Example entries (remove the leading # and edit):
$PathMap = @(
    # @{ From = '/downloads';   To = 'D:\Torrents' },
    # @{ From = '/data/media';  To = '\\NAS\media' }
)
# -----------------------------------------------------------------------------

$logFile = Join-Path $PSScriptRoot 'last-error.txt'
try {
    if (-not $Url) { throw 'No URL given' }

    $raw  = $Url -replace '^qbitopen:(//)?', ''
    $raw  = $raw.TrimEnd('/')
    $path = [System.Uri]::UnescapeDataString($raw)

    foreach ($m in $PathMap) {
        if ($path.StartsWith($m.From, [System.StringComparison]::OrdinalIgnoreCase)) {
            $path = $m.To + $path.Substring($m.From.Length)
            break
        }
    }

    # qBittorrent reports forward slashes even on Windows
    $path = $path -replace '/', '\'

    # Safety: only ever accept an absolute local (C:\...) or UNC (\\server\...) path
    if ($path -notmatch '^([A-Za-z]:\\|\\\\)') { throw "Not an absolute Windows path: $path" }
    if ($path.Contains('"'))                   { throw 'Invalid character in path' }

    # If the exact path is gone (moved, or incomplete files carry a .!qB suffix),
    # fall back to the nearest parent folder that exists.
    $target = $path
    while (-not (Test-Path -LiteralPath $target)) {
        $parent = Split-Path -Parent $target
        if ([string]::IsNullOrEmpty($parent) -or $parent -eq $target) { throw "Path not found: $path" }
        $target = $parent
    }

    if (Test-Path -LiteralPath $target -PathType Container) {
        # Folder: open it
        $t = $target.TrimEnd('\')
        if ($t -match '^[A-Za-z]:$') {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ($t + '\')
        } else {
            Start-Process -FilePath 'explorer.exe' -ArgumentList ('"{0}"' -f $t)
        }
    } else {
        # Single file: open its folder with the file highlighted (never executes it)
        Start-Process -FilePath 'explorer.exe' -ArgumentList ('/select,"{0}"' -f $target)
    }
}
catch {
    ("{0}  {1}`r`n{2}" -f (Get-Date), $Url, ($_ | Out-String)) | Set-Content -Path $logFile
}
'@

# ---------------------------------------------------------------------------
# launch.vbs - starts the handler with NO visible console window
# ---------------------------------------------------------------------------
$vbs = @'
Set sh = CreateObject("WScript.Shell")
If WScript.Arguments.Count > 0 Then
  here = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
  url  = Replace(WScript.Arguments(0), """", "")
  sh.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & here & "handler.ps1"" """ & url & """", 0, False
End If
'@

$handlerPath = Join-Path $dir 'handler.ps1'
$vbsPath     = Join-Path $dir 'launch.vbs'
Set-Content -Path $handlerPath -Value $handler -Encoding UTF8
Set-Content -Path $vbsPath     -Value $vbs     -Encoding ASCII

# ---------------------------------------------------------------------------
# Register the qbitopen: URL protocol for the current user
# ---------------------------------------------------------------------------
New-Item -Path $root -Force | Out-Null
Set-ItemProperty -Path $root -Name '(default)' -Value 'URL:qBit Open Folder'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$root\shell\open\command" -Name '(default)' -Value ('wscript.exe "{0}" "%1"' -f $vbsPath)

Write-Host ''
Write-Host 'Installed.' -ForegroundColor Green
Write-Host "Files: $dir"
Write-Host ''
Write-Host 'First click on the folder button: your browser asks to open "qbitopen Handler".'
Write-Host 'Tick "Always allow" and confirm - it will not ask again.'
Write-Host ''
Write-Host 'If qBittorrent runs on a different machine / Docker / NAS, edit $PathMap at the top of:'
Write-Host "  $handlerPath"
Write-Host 'If a click does nothing, check last-error.txt in the same folder.'
Write-Host ''
Read-Host 'Press Enter to close'
