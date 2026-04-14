# yt-dlp stahovač

Native macOS application for downloading audio from websites (primarily Czech Radio – Český rozhlas) with automatic metadata embedding, quality selection, and intelligent playlist management.

![macOS](https://img.shields.io/badge/macOS-10.13+-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Bash](https://img.shields.io/badge/Shell_Script-121011?logo=gnu-bash)

## Features

### Core
- 🎙️ **Download audio** from websites (yt-dlp compatible)
- 📁 **Smart folder naming** – prefers series name, then playlist title, then uploader
- 🏷️ **Automatic metadata** – embeds title, artist, cover art into MP3 files
- 🎚️ **Quality selection** – choose between 128/192/320 kbps MP3
- 📋 **Multiple input methods**
  - Double-click → URL dialog
  - Drag-drop → .txt file with URLs (one per line)
  - System Service → right-click selected URL in any app

### Smart Features
- 💾 **Download archive** – never re-downloads same episode (`.archive.txt` tracks IDs)
- 📜 **URL history** – stores last 10 URLs, quick-select from dialog
- ⚙️ **Auto-update** – yt-dlp updates silently before each download
- 🔔 **macOS notifications** – alerts on completion or error
- 📦 **Batch downloads** – "Ze souboru…" button loads URLs from text file
- 🎬 **Watchlist** – auto-sync favorite shows every Monday at 8:00 AM

### Optional
- 🍎 **System Service** – right-click → "Stáhnout přes yt-dlp"
- 📊 **Menubar plugin** – SwiftBar/xbar integration with quick actions
- ⏰ **Weekly automation** – LaunchAgent syncs watchlist automatically

## Installation

### Requirements
- macOS 10.13+
- Homebrew (for yt-dlp and ffmpeg)

### Quick Install

1. **Download installer:**
   ```bash
   curl -o install-ytdlp-stahovac.sh https://raw.githubusercontent.com/jaroslavtomecek/yt-dlp-stahovac/main/install-ytdlp-stahovac.sh
   ```

2. **Run installer:**
   ```bash
   bash install-ytdlp-stahovac.sh
   ```

   The installer will:
   - Create `/Applications/yt-dlp stahovač.app`
   - Install dependencies (yt-dlp, ffmpeg) if missing
   - Set up System Service for right-click context menu
   - Create LaunchAgent for watchlist automation
   - Set up SwiftBar plugin (if SwiftBar installed)

3. **That's it!** The app is ready to use.

## Usage

### Basic Download (Double-click)
1. Open the app
2. Enter URL (clipboard is pre-filled if valid)
3. Select quality (192 kbps recommended)
4. Downloads appear in `~/Downloads/yt-dlp/<Show Name>/`

### Batch Download (Drag-Drop)
1. Create `.txt` file with URLs:
   ```
   # My shows
   https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
   https://www.mujrozhlas.cz/osobnost-dne
   https://www.radiozurnal.cz/zaznamy
   ```
2. Drag the file onto app icon → select quality → done

### System Service (Right-click)
1. Select a URL in Safari, Mail, or any app
2. Right-click → Services → "Stáhnout přes yt-dlp"
3. Select quality in dialog
4. Downloads in background

### Watchlist (Weekly Auto-sync)
1. Open `~/.ytdlp_watchlist` in text editor
2. Add show URLs (one per line):
   ```
   # Favorite shows
   192:https://www.mujrozhlas.cz/zaznamy-emisni-archiv
   320:https://www.radiozurnal.cz/zaznamy
   https://www.irozhlas.cz/news-podcast
   ```
   (Optional quality prefix: `bitrate:url`)
3. Every Monday at 8:00 AM, new episodes download automatically
4. View log: `~/Downloads/yt-dlp-watchlist.log`

### SwiftBar Integration
If using [SwiftBar](https://swiftbar.app/) or [xbar](https://xbarapp.com/):
1. Install via Homebrew: `brew install --cask swiftbar`
2. Copy plugin file to SwiftBar Plugins folder (installer tells you where)
3. Menubar icon appears – quick access to download, watchlist sync, folder

## Output Structure

```
~/Downloads/yt-dlp/
├── Show Name 1/
│   ├── 01 - Episode Title.mp3
│   ├── 02 - Episode Title.mp3
│   └── ...
├── Show Name 2/
│   ├── 01 - Episode Title.mp3
│   └── ...
├── .archive.txt          # Internal: tracks downloaded IDs
└── [logs]
```

## Files & Locations

| File | Purpose |
|------|---------|
| `~/.ytdlp_history` | Last 10 downloaded URLs (for quick-select) |
| `~/.ytdlp_watchlist` | Favorite shows for weekly auto-sync |
| `~/Downloads/yt-dlp/.archive.txt` | Downloaded episode IDs (prevents re-downloads) |
| `~/Downloads/yt-dlp-last.log` | Last download log |
| `~/Downloads/yt-dlp-watchlist.log` | Watchlist sync log |
| `~/Library/LaunchAgents/cz.tomecek.ytdlp-watchlist.plist` | Weekly scheduler |
| `~/Library/Services/Stáhnout přes yt-dlp.workflow` | System Service |

## Architecture

### Components
- **worker.sh** – Main logic (dialogs, history, downloads)
- **watchlist-sync.sh** – Processes watch list weekly
- **LaunchAgent** – Runs watchlist-sync.sh every Monday 8:00 AM
- **Automator Service** – Integrates with system right-click menu
- **SwiftBar Plugin** – Optional menubar widget

### Technology Stack
- **Language**: Bash + AppleScript
- **Download Engine**: yt-dlp
- **Audio Processing**: ffmpeg
- **Notification**: macOS native notifications
- **Package Management**: Homebrew

## Troubleshooting

### "The application cannot be opened because its executable is missing"
Usually from Gatekeeper on first run:
1. Control-click (right-click) app icon
2. Click "Open"
3. Click "Open" in confirmation dialog
4. On next run, you can double-click normally

### "Permission denied: Terminal"
macOS blocks unsigned apps from controlling Terminal:
1. System Settings → Privacy & Security → Automation
2. Find "yt-dlp stahovač" and enable Terminal access
3. Or: `tccutil reset AppleEvents cz.tomecek.ytdlpstahovac`

### "Chybí závislosti: yt-dlp ffmpeg"
Dependencies not installed:
1. App offers to open Terminal with install command
2. Or manually: `brew install yt-dlp ffmpeg`

### Download fails silently
Check logs:
- Last download: `cat ~/Downloads/yt-dlp-last.log`
- Watchlist: `cat ~/Downloads/yt-dlp-watchlist.log`

## Configuration

### Audio Quality
- **128 kbps** – Smallest files, acceptable for speech/podcasts
- **192 kbps** – Recommended (good quality/size balance)
- **320 kbps** – Highest quality, larger files

Select during each download, or prefix in watchlist: `320:https://...`

### Update Interval
App automatically updates yt-dlp before each download (quietly).
To manually update: `yt-dlp -U`

### Disable Watchlist
Remove LaunchAgent:
```bash
launchctl unload ~/Library/LaunchAgents/cz.tomecek.ytdlp-watchlist.plist
```

## Supported Sites

Works with any site supported by [yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/README.md#supported-sites), including:
- Český rozhlas (ČRo) – all stations
- Spotify podcasts
- YouTube
- SoundCloud
- Bandcamp
- And 1000+ others

To check if a site works: `yt-dlp --list-extractors | grep site-name`

## Development

### Building from Source
```bash
# Clone repo
git clone https://github.com/jaroslavtomecek/yt-dlp-stahovac.git
cd yt-dlp-stahovac

# Run installer
bash install-ytdlp-stahovac.sh
```

### File Structure
```
.
├── install-ytdlp-stahovac.sh    # Main installer (builds everything)
├── README.md
├── LICENSE (MIT)
└── CHANGELOG.md                  # Version history
```

### Modifying Scripts
1. Edit `install-ytdlp-stahovac.sh`
2. Run installer to test
3. Commit changes

### Testing
```bash
# Syntax check
bash -n install-ytdlp-stahovac.sh

# Install to ~/Applications instead of /Applications
# (installer checks write permissions automatically)
```

## Changelog

### v2.0 (Latest)
- ✅ Download archive (never re-downloads)
- ✅ URL history with quick-select
- ✅ "Ze souboru…" button for batch downloads
- ✅ Auto-update yt-dlp before downloads
- ✅ macOS notifications on completion/error
- ✅ Series folder naming (better for ČRo shows)
- ✅ System Service (right-click context menu)
- ✅ SwiftBar/xbar menubar plugin
- ✅ Watchlist with weekly LaunchAgent

### v1.0
- Basic download functionality
- URL dialog + quality selection
- Drag-drop file support
- Metadata embedding

## License

MIT License – See [LICENSE](LICENSE) file

## Author

Created for personal use with ❤️ for Czech Radio content.

## Contributing

Suggestions & bug reports welcome! Please open an issue on GitHub.

## FAQ

**Q: Will this work on Intel Macs?**  
A: Yes! The installer detects your Mac's architecture and installs compatible Homebrew binaries.

**Q: Can I use this with non-ČRo sites?**  
A: Yes! Works with any yt-dlp-supported site.

**Q: Does the watchlist run even if the Mac is sleeping?**  
A: Only if you have "Wake for network access" enabled in Energy Saver settings. Otherwise it runs next time the Mac wakes at 8:00 AM.

**Q: How do I uninstall?**  
A: 
```bash
# Remove app
rm -rf /Applications/yt-dlp\ stahovač.app

# Disable watchlist automation
launchctl unload ~/Library/LaunchAgents/cz.tomecek.ytdlp-watchlist.plist

# Remove system service
rm -rf ~/Library/Services/Stáhnout\ přes\ yt-dlp.workflow

# Remove SwiftBar plugin (if used)
rm ~/Library/Application\ Support/SwiftBar/Plugins/yt-dlp.1h.sh

# Optionally remove user files
# rm ~/.ytdlp_history ~/.ytdlp_watchlist ~/Downloads/yt-dlp-*
```

**Q: Can I customize the output folder?**  
A: Currently hardcoded to `~/Downloads/yt-dlp/`. To change: edit the `OUTBASE` variable in `worker.sh` within the installer script.

---

**Built with** Bash, AppleScript, yt-dlp, and lots of ☕
