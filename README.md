# qbitwebber (modified fork)

A modified fork of [ksuaning-au/qbitwebber](https://github.com/ksuaning-au/qbitwebber), a minimalist, mobile-friendly frontend for the qBittorrent web UI.

> **This repository is an archive.** It contains only the built release (the `public` folder) plus a Windows helper script. The original TypeScript source is not included. I am not accepting issues or pull requests and don't plan to maintain it. For the source, development setup and demo mode, see the [original repository](https://github.com/ksuaning-au/qbitwebber). All credit for the app goes to its author.

## Changes from the original

- **Open folder button** on each torrent. It opens the torrent's location in Windows File Explorer (the file is highlighted if the torrent is a single file). Requires the one-time setup below.
- **Torrent list** now defaults to sorting by **Added, newest first** (was Name, A to Z).
- **Search page** now supports **two-level sorting**, defaulting to **Date descending, then Seeds descending** (was Seeds only).
  - Click a column header to make it the primary sort. The previous primary becomes the secondary.
  - Clicking the current primary flips its direction. Clicking the secondary promotes it to primary.
  - Headers show a small `1` / `2` next to the arrow. On mobile the sort menu shows the same markers.
- **Logs page** fixed: the page itself no longer scrolls. It fits the screen and only the log panel scrolls.
- **RSS page** reworked:
  - Articles are sorted newest first, with unread counts per feed and in the feed list.
  - Each article has a download button, and downloading marks it as read.
  - New refresh-all button (feeds are re-polled a few seconds later so new items show up).
  - A banner appears when RSS fetching is turned off in qBittorrent, with a button to enable it.
  - Only `http`, `https` and `magnet` links are accepted, HTML is stripped from descriptions, and load errors are shown.
  - Removing a feed asks for confirmation.
- **Login / session** fixes:
  - A request that fails with 403 (expired session) now logs in again automatically and retries once, instead of dropping you back to the login screen.
  - The login form shows a "Connecting..." state and displays the error message.
  - qBittorrent's `Fails.` response is treated as a failed login.
- **Add torrent** now shows an error when qBittorrent rejects a torrent (duplicate or invalid) instead of reporting success.
- **File priorities** use each file's real index from qBittorrent, so priority changes hit the correct file.

## Installation

1. In qBittorrent, go to **Options > Web UI > Use alternative Web UI** and set the path to this repo's `public` folder.
2. (Optional, Windows only) Set up the open folder button, see below.

## Open folder button setup (Windows)

Browsers can't open local folders from a web page, so the button uses a custom `qbitopen:` link. A small handler has to be registered with Windows once. That is what `install-qbitopen.ps1` does:

- Right-click `install-qbitopen.ps1` and choose **Run with PowerShell**. No admin rights are needed, and it registers for the current user only.
- If PowerShell blocks it, run:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1
  ```
- The first time you click the button, your browser asks to open "qbitopen Handler". Tick **Always allow** and confirm.

What it installs:

- `%LOCALAPPDATA%\qbitopen\handler.ps1` and `launch.vbs`
- A `qbitopen:` URL protocol under `HKCU\Software\Classes\qbitopen`

The handler only accepts absolute local (`C:\...`) or UNC (`\\server\...`) paths. It only ever opens Explorer and never executes files.

**If qBittorrent runs on another machine, in Docker, on a NAS or in WSL**, the paths it reports won't exist on Windows. Edit `$PathMap` at the top of `%LOCALAPPDATA%\qbitopen\handler.ps1` to map them, for example `@{ From = '/downloads'; To = 'D:\Torrents' }`.

If a click does nothing, check `last-error.txt` in `%LOCALAPPDATA%\qbitopen`.

**Uninstall:**

```powershell
powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Uninstall
```

## Disclaimer

As in the original: this is a minimal UI and is likely missing things, and you should only ever use it to download Linux distros and nothing else.
