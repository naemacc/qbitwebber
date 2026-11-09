# qbitwebber (modified fork)

A modified fork of [ksuaning-au/qbitwebber](https://github.com/ksuaning-au/qbitwebber), a minimalist, mobile-friendly frontend for the qBittorrent web UI.

> [!NOTE]
> **This repository is an archive.** It contains only the built release (the `public` folder) plus a Windows helper script. The original TypeScript source is not included. I am not accepting issues or pull requests and don't plan to maintain it. For the source, development setup and demo mode, see the [original repository](https://github.com/ksuaning-au/qbitwebber). All credit for the app goes to its author.

## Changes from the original

### Look and feel

- **Card theme** for the torrent, search and RSS cards:
  - Rounded cards with two-line titles.
  - An **uppercase status row** at the top of each card.
  - Size, speed, ETA, date and similar info shown as small **pill chips**.
  - A thin, neutral progress bar on torrent cards. The status text carries the state color, so the bar is not colored.
- **Seed availability color** (green for 10+ seeds, yellow for 1 to 9, red for 0):
  - On the **search page** it colors the status text (`12 SEEDS • 3 LEECHES`).
  - On the **RSS page** it colors the RSS icon on each article card.
- **Interface size** setting retuned: Small, Normal and Large are each noticeably bigger than before.
- **Torrent cards on mobile** show the ETA directly in the card instead of behind the expand button.
- **Quieter secondary buttons**: Mark all read, Mark as read and Copy all (logs) are smaller, outlined and muted, so they don't compete with the main actions.

### Torrents

- **Open folder button** on each torrent. It opens the torrent's location in Windows File Explorer (the file is highlighted if the torrent is a single file). Requires the one-time setup below.
- **Delete confirmation**: deleting a torrent (single or bulk) now asks first, with an **Also delete downloaded files** checkbox. Previously delete had no confirmation.
- **Torrent list** now defaults to sorting by **Added, newest first** (was Name, A to Z).
- **Add torrent** now shows an error when qBittorrent rejects a torrent (duplicate or invalid) instead of reporting success.
- **File priorities** use each file's real index from qBittorrent, so priority changes hit the correct file.

### Long lists

- New **Long lists** setting under **Settings > Appearance**:
  - **Infinite scroll** (default): the first 40 items are shown and the next 40 load as you scroll near the bottom. Changing the sort or starting a new search resets the list to the top.
  - **Pages**: 20 items per page with previous and next buttons.
- It applies to both the torrent list and the search results. The setting is stored in the browser, so it can differ per device.
- The original search pager only existed on the desktop table. In Pages mode it now also shows on mobile.

### Search

- **Two-level sorting**, defaulting to **Date descending, then Seeds descending** (was Seeds only).
  - Two side-by-side dropdowns above the results let you pick the primary and secondary sort field, each with its own direction toggle. This works on desktop and mobile.
  - Dates are compared by calendar day, so the second sort breaks ties between results from the same day (for example, Date then Seeds ranks same-day results by seeds).
  - Clicking a table column header also works: it becomes the primary sort and the previous primary becomes the secondary. Headers show a small `1` / `2` next to the arrow.
- The expanded card on mobile also shows the full date and time, seed/leech ratio, exact size in bytes, link type and, for magnet links, the info hash and tracker count.
- **No 60 second cutoff.** A search now keeps polling until qBittorrent reports it finished (with a 10 minute safety cap), so slow plugins are no longer dropped. Results still appear as they arrive, and the cancel button still works at any time.

### RSS

- Articles are sorted newest first, with unread counts per feed and in the feed list.
- Each article has a download button, and downloading marks it as read.
- New refresh-all button (feeds are re-polled a few seconds later so new items show up).
- A banner appears when RSS fetching is turned off in qBittorrent, with a button to enable it.
- Only `http`, `https` and `magnet` links are accepted, HTML is stripped from descriptions, and load errors are shown.
- The description line no longer repeats the torrent title.
- Removing a feed asks for confirmation in an in-app dialog, the same style as torrent delete.
- **Adding a feed without a name now works** (the name field is optional). The feed is named after its site, for example `nyaa.si`.
- Feeds show the **name you entered**. The site name is shown only when no name was given.
- Feeds can be **edited** (name and URL) from the new Edit button on each feed card. Changing the URL needs qBittorrent 4.5 or newer.
- Individual articles can be **marked as read** with a button under the timestamp. It disappears once the article is read.
- **Mobile:** the feed list shows one feed at a time and snaps horizontally. The feed you swipe to is selected once the snap settles.
- **Desktop:** the feed list shows at most 2 feeds and scrolls vertically.
- Each article has a soft, rounded **download strip** at the right edge of its card. It sits beside the article text, so when the label expands on hover it pushes the text instead of covering it. On mobile the whole strip is tappable, and on desktop you click the button.
- Articles show **size, seeders and leechers** when the feed provides them (as data fields, in the description, or as a magnet `xl` size). Size is a chip, and seeders and leechers go in the status row at the top of the card. Anything the feed doesn't provide is simply not shown. qBittorrent's RSS API doesn't pass these through for every feed (nyaa, for example, keeps them in custom fields it drops), so some feeds show no seed or leech info.
- On mobile the Mark as read button spans the full card width, and the header shows the qBittorrent wordmark on the right.
- The action buttons on feed and article cards follow the **interface size and button label** settings, and are vertically centered on the card.

### Settings

- **Start paused** and **Create subfolder** now work on current qBittorrent (5.x / 4.6+), which renamed the underlying settings. Older versions still work.
- The **Theme** button now shows the theme actually in use. Before, it showed "Light" while the UI was dark whenever the theme was set to follow the system.
- The **Temp folder** field is greyed out and disabled while **Enable temp folder** is unticked. The path you typed is kept.
- After saving, the page re-reads qBittorrent's settings and shows a warning if any saved value was not applied.

### Logs

- The page itself no longer scrolls. It fits the screen and only the log panel scrolls.

### Login and session

- A request that fails with 403 (expired session) now logs in again automatically and retries once, instead of dropping you back to the login screen.
- The login form shows a "Connecting..." state and displays the error message.
- qBittorrent's `Fails.` response is treated as a failed login.

## Installation

1. Download the zipped folder from the release page or clone the repo.
2. In qBittorrent, go to **Options > Web UI > Use alternative Web UI** and set the path to this repo's `public` folder (the one containing `index.html`).
3. (Optional, Windows only) Set up the open folder button, see below.

## Open folder button setup (Windows)

Browsers can't open local folders from a web page, so the button uses a custom `qbitopen:` link. A small handler has to be registered with Windows once. That is what `install-qbitopen.ps1` does:

- Right-click `install-qbitopen.ps1` and choose **Run with PowerShell**. No admin rights are needed, and it registers for the current user only.
- If PowerShell blocks it, run:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1
  ```
- The first time you click the button, your browser may ask to open "qbitopen Handler". Tick **Always allow** and confirm.

What it installs:

- A `qbitopen` folder **next to the installer** (nothing is written anywhere else), containing:
  - `handler.ps1` and `launch.vbs`, which receive the click and open Explorer.
  - `pathmap.json`, your path mapping (see below).
  - `last-error.txt`, only if something went wrong.
- A `qbitopen:` URL protocol under `HKCU\Software\Classes\qbitopen`.

The `qbitopen` folder sits beside `public`, not inside it.

The handler only accepts absolute local (`C:\...`) or UNC (`\\server\...`) paths. It only ever opens Explorer and never executes files. If the exact path no longer exists (moved, or an unfinished download with a `.!qB` suffix), it opens the nearest parent folder that does.

**If qBittorrent runs on another machine, in Docker, on a NAS or in WSL**, the paths it reports won't exist on Windows. Edit `qbitopen\pathmap.json` to map them. The installer creates it with a disabled example. The first matching entry wins:

```json
[
  {
    "enabled": true,
    "from": "/downloads",
    "to": "D:/Torrents"
  }
]
```

- `from` is the path as qBittorrent reports it, and `to` is the same folder on Windows.
- Use forward slashes in `to`. If you use backslashes, JSON needs them doubled (`D:\\Torrents`).
- For Docker, `to` is the host side of your volume. For `./downloads:/downloads` in a compose file, that is the full path of the `downloads` folder next to that compose file.
- Changes apply on the next click. No restart needed. A typo in the JSON is written to `last-error.txt`.

Things to know:

- Re-running the installer rewrites `handler.ps1` and `launch.vbs` but keeps your `pathmap.json`.
- Windows stores the installer's location in the registry. If you move or rename the folder, run the installer again.
- To use a different location, run it with `-Dir`:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Dir 'D:\somewhere\qbitopen'
  ```
- If you installed an earlier version that used `%LOCALAPPDATA%\qbitopen`, run the new installer and then delete that old folder by hand.
- If a click does nothing, check `last-error.txt` in the `qbitopen` folder.

**Uninstall:**

```powershell
powershell -ExecutionPolicy Bypass -File .\install-qbitopen.ps1 -Uninstall
```

This removes the registry entry and the `qbitopen` folder.

## Disclaimer

As in the original: this is a minimal UI and is likely missing things.
