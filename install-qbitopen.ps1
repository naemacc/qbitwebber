# install-qbitopen.ps1
# One-time setup so the "open folder" button in the web UI can open Windows Explorer.
# No admin rights needed (registers for the current user only).
#
#   Install:    right-click > Run with PowerShell
#               (or: powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1)
#   Uninstall:  powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Uninstall
#   Custom dir: powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Dir 'D:\somewhere\qbitopen'
#
# The handler files are created in a "qbitopen" folder next to this script, so
# nothing is written outside the folder you downloaded. That folder sits beside
# (not inside) the "public" folder qBittorrent serves, so it is not exposed by
# the web UI. Your path map lives in its own file (pathmap.json) and is never
# overwritten when you re-run this installer.

param(
  [switch]$Uninstall,
  [string]$Dir
)

$ErrorActionPreference = 'Stop'

if (-not $Dir) { $Dir = Join-Path $PSScriptRoot 'qbitopen' }
$root = 'HKCU:\Software\Classes\qbitopen'

if ($Uninstall) {
  if (Test-Path $root) { Remove-Item -Path $root -Recurse -Force }
  if (Test-Path $Dir) { Remove-Item -Path $Dir -Recurse -Force }
  Write-Host 'Uninstalled.'
  Read-Host 'Press Enter to close'
  exit 0
}

New-Item -ItemType Directory -Force -Path $Dir | Out-Null

# ---------------------------------------------------------------------------
# handler.ps1 - receives  qbitopen:<url-encoded path>  and opens Explorer
# ---------------------------------------------------------------------------
$handler = @'
param([string]$Url)

# Path mapping lives in pathmap.json (same folder). Only needed if qBittorrent
# does NOT run on this PC (Docker, NAS, WSL, remote box).
$mapFile = Join-Path $PSScriptRoot 'pathmap.json'
$logFile = Join-Path $PSScriptRoot 'last-error.txt'
try {
    if (-not $Url) { throw 'No URL given' }

    $PathMap = @()
    if (Test-Path -LiteralPath $mapFile) {
        $PathMap = @(Get-Content -Raw -LiteralPath $mapFile | ConvertFrom-Json)
    }

    $raw  = $Url -replace '^qbitopen:(//)?', ''
    $raw  = $raw.TrimEnd('/')
    $path = [System.Uri]::UnescapeDataString($raw)

    foreach ($m in $PathMap) {
        if ($m.enabled -eq $false -or -not $m.from) { continue }
        if ($path.StartsWith($m.from, [System.StringComparison]::OrdinalIgnoreCase)) {
            $path = $m.to + $path.Substring($m.from.Length)
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

$handlerPath = Join-Path $Dir 'handler.ps1'
$vbsPath = Join-Path $Dir 'launch.vbs'
$mapPath = Join-Path $Dir 'pathmap.json'
Set-Content -Path $handlerPath -Value $handler -Encoding UTF8
Set-Content -Path $vbsPath -Value $vbs -Encoding ASCII

# ---------------------------------------------------------------------------
# pathmap.json - created once, then left alone on re-installs
# ---------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $mapPath)) {
  $mapText = @'
[
  {
    "enabled": false,
    "from": "/downloads",
    "to": "D:/path/to/your/downloads"
  }
]
'@
  Set-Content -Path $mapPath -Value $mapText -Encoding UTF8
  $mapNote = 'Created pathmap.json with a disabled example. Edit it if qBittorrent runs in Docker, on a NAS or in WSL.'
} else {
  $mapNote = 'Kept your existing pathmap.json.'
}

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
Write-Host "Files:    $Dir"
Write-Host "Path map: $mapPath"
Write-Host $mapNote
Write-Host ''
Write-Host 'First click on the folder button: your browser may ask to open "qbitopen Handler".'
Write-Host 'Tick "Always allow" and confirm - it will not ask again.'
Write-Host 'If a click does nothing, check last-error.txt in the Files folder.'
Write-Host ''
Read-Host 'Press Enter to close'
