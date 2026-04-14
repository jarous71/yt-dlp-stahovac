# yt-dlp stahovač

Native macOS application for downloading **audio and video** from 1500+ websites with intelligent content auto-detection, metadata embedding, quality selection, and playlist management.

**Works with:** Czech Radio (Český rozhlas) • YouTube • Facebook • TikTok • Instagram • Vimeo • Bluesky • Twitch • Podcasts • SoundCloud • and many more...

![macOS](https://img.shields.io/badge/macOS-10.13+-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Bash](https://img.shields.io/badge/Shell_Script-121011?logo=gnu-bash)
![Version](https://img.shields.io/badge/v3.0-video--support-brightgreen)

## Features

### Core
- 🎙️ **Audio & Video downloads** – automatically detects content type and downloads accordingly
- 📁 **Smart folder naming** – prefers series name, then playlist title, then uploader
- 🏷️ **Automatic metadata** – embeds title, artist, cover art (audio) or metadata (video)
- 🎚️ **Quality selection** 
  - Audio: 128/192/320 kbps MP3
  - Video: 1080p / 720p / 480p / 360p MP4
- 📋 **Multiple input methods**
  - Double-click → URL dialog
  - Drag-drop → .txt file with URLs (one per line)
  - System Service → right-click selected URL in any app

### Smart Features
- 🤖 **Auto-detection** – recognizes audio podcasts vs. video content by domain
  - Audio sources: Český rozhlas, podcasts, SoundCloud, Spotify...
  - Video sources: YouTube, Facebook, TikTok, X/Twitter, Vimeo, Bluesky, Twitch...
- 💾 **Download archive** – never re-downloads same episode (`.archive.txt` tracks IDs)
- 📜 **URL history** – stores last 10 URLs, quick-select from dialog
- ⚙️ **Auto-update** – yt-dlp updates silently before each download
- 🔔 **macOS notifications** – alerts on completion or error
- 📦 **Batch downloads** – "Ze souboru…" button loads URLs from text file
- 🎬 **Watchlist** – auto-sync favorite shows & videos every Monday at 8:00 AM
- 🎬 **Mixed content** – same watchlist handles both audio and video with auto-detection

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
2. Enter or paste URL (clipboard is pre-filled if valid)
3. App **auto-detects** content type and asks:
   - 🎙️ **Audio content** (Český rozhlas, podcasts) → "Audio nebo video?" → select quality (128/192/320 kbps)
   - 🎬 **Video content** (YouTube, Facebook, TikTok, etc.) → "Video nebo audio?" → select quality (1080p/720p/480p/360p)
4. You can override the auto-detected type if needed
5. Downloads appear in `~/Downloads/yt-dlp/<Show Name>/` with proper folder structure

**Example – YouTube video:**
```
URL: https://www.youtube.com/watch?v=_q54Q-aDBwE
App detects: VIDEO
Dialog: "Detekován video obsah. Chceš video nebo audio?"
Quality: 720p selected
Result: ~/Downloads/yt-dlp/Grandpa Cooks Today/01 - Bramborová omáčka s vejci.mp4 ✅
```

**Example – ČRo podcast:**
```
URL: https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
App detects: AUDIO
Dialog: "Detekován audio podcast. Chceš audio nebo video?"
Quality: 192 kbps selected
Result: ~/Downloads/yt-dlp/Přehled zpráv iRozhlas/01 - Přehled zpráv.mp3 ✅
```

### Auto-Detection
The app intelligently recognizes content type:

| Source | Detected As | Default Quality |
|--------|-------------|-----------------|
| Český rozhlas (všechny stanice) | Audio | 192 kbps |
| Podcast services | Audio | 192 kbps |
| YouTube, Vimeo | Video | 720p |
| Facebook, X/Twitter, TikTok | Video | 720p |
| Instagram, Twitch | Video | 720p |
| Bluesky (video posts) | Video | 720p |
| Unknown sources | Auto-ask user | — |

You can always change the detected type in the dialog before downloading.

### Batch Download (Drag-Drop)
1. Create `.txt` file with URLs:
   ```
   # My shows - audio podcasts
   https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
   https://www.mujrozhlas.cz/osobnost-dne
   
   # My videos
   https://www.youtube.com/watch?v=example
   https://www.facebook.com/page/videos
   ```
2. Drag the file onto app icon → for each URL, select type (auto-detected) → select quality → done

### System Service (Right-click)
1. Select a URL in Safari, Mail, or any app
2. Right-click → Services → "Stáhnout přes yt-dlp"
3. Select quality in dialog
4. Downloads in background

### Watchlist (Weekly Auto-sync)
1. Open `~/.ytdlp_watchlist` in text editor
2. Add show URLs and videos (one per line):
   ```
   # Audio podcasts (auto-detected as audio)
   https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
   192:https://www.mujrozhlas.cz/zaznamy-emisni-archiv
   audio:320:https://www.radiozurnal.cz/zaznamy
   
   # Videos (auto-detected as video)
   https://www.youtube.com/user/example/videos
   video:720:https://www.facebook.com/page/videos
   video:1080:https://www.youtube.com/@channel
   ```
3. Format options:
   - `https://example.com` – auto-detect type, use default quality
   - `audio:192:https://...` – force audio, 192 kbps
   - `audio:320:https://...` – force audio, 320 kbps
   - `video:480:https://...` – force video, 480p
   - `video:1080:https://...` – force video, 1080p
4. Every Monday at 8:00 AM, new episodes download automatically
5. View log: `~/Downloads/yt-dlp-watchlist.log`

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

## Real-World Examples

### Example 1: Download YouTube Cooking Video
```
1. Click app → URL field shows clipboard content
2. Paste: https://www.youtube.com/watch?v=_q54Q-aDBwE
3. App displays: "Detekován video obsah. Chceš video nebo audio?"
4. Select: "Video (MP4)"
5. Quality dialog: 720p selected
6. Download starts → ~/Downloads/yt-dlp/Grandpa Cooks Today/01 - Bramborová omáčka.mp4
Result: ✅ 50MB video with metadata in 30 seconds
```

### Example 2: Download ČRo Podcast
```
1. Click app
2. Paste: https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
3. App displays: "Detekován audio podcast. Chceš audio nebo video?"
4. Select: "Audio (MP3)" (already default)
5. Quality dialog: 192 kbps selected
6. Download starts → ~/Downloads/yt-dlp/Přehled zpráv iRozhlas/
Result: ✅ All episodes as MP3s with metadata
```

### Example 3: Watchlist with Mixed Content
Create `~/.ytdlp_watchlist`:
```bash
# ČRo podcasts (auto-detected as audio, 192 kbps)
https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
https://www.mujrozhlas.cz/osobnost-dne

# YouTube channels (auto-detected as video, 720p)
https://www.youtube.com/@CookingChannel/videos

# Explicit specifications
audio:320:https://www.radiozurnal.cz/zaznamy
video:1080:https://www.facebook.com/channel/videos
```

Every Monday at 8:00 AM:
- ✅ New ČRo episodes → MP3 (192 kbps)
- ✅ New YouTube videos → MP4 (720p)
- ✅ New Radiožurnál episodes → MP3 (320 kbps)
- ✅ New Facebook videos → MP4 (1080p)
All stored in `~/Downloads/yt-dlp/` with proper folder structure.

## Supported Sites

Works with any site supported by [yt-dlp](https://github.com/yt-dlp/yt-dlp/blob/master/README.md#supported-sites) (1500+ sources).

### Auto-Detected as Audio
- Český rozhlas – all stations (ČRo1, ČRo2, ČRo3, Mujrozhlas, ...)
- Radiožurnál
- Spotify podcasts
- SoundCloud
- Apple Podcasts
- Anchor
- And similar podcast/radio platforms

### Auto-Detected as Video
- **YouTube** – videos, playlists, channels
- **Facebook** – videos, pages, groups
- **X/Twitter** – video posts
- **TikTok** – videos
- **Instagram** – reels, stories, videos
- **Vimeo** – videos, channels
- **Bluesky** – video posts
- **Twitch** – streams, VODs
- **Reddit** – videos, clips
- And 1500+ other sites supported by yt-dlp

### Others
- Bandcamp
- PornHub (age check bypassed automatically)
- And many more...

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

### v3.0 (Latest) – Video Support Release
#### New Features
- ✅ **Audio & Video support** – automatically detects content type by source domain
- ✅ **Smart quality dialogs** – different options for audio (128/192/320 kbps) vs. video (1080p/720p/480p/360p)
- ✅ **Video format support** – downloads as MP4 with embedded metadata
- ✅ **Mixed watchlist** – same watchlist handles audio and video with auto-detection
- ✅ **Video format specifiers** – `video:720:url` syntax for explicit control in watchlist
- ✅ **Improved auto-detection** – recognizes 15+ video platforms (YouTube, Facebook, TikTok, Vimeo, Bluesky, Twitch, Instagram, Reddit, etc.)
- ✅ **Type override** – always ask user to confirm auto-detected type before downloading

#### Bug Fixes
- ✅ Fixed AppleScript dialog logic for correct button detection
- ✅ Fixed shell command escaping in .command file generation (YouTube downloads now work)
- ✅ Proper environment variable passing to avoid backslash interpretation issues
- ✅ Robust yt-dlp command construction for both audio and video formats

### v2.0
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

**Q: How does auto-detection work? Can I disable it?**  
A: App checks the URL domain against known patterns:
- If matches audio source (rozhlas, podcast, spotify, soundcloud) → assumes audio
- If matches video source (youtube, facebook, x.com, tiktok, vimeo, bluesky, twitch) → assumes video
- For unknown sources → asks user directly

You can always override the detected type in the dialog before downloading. There's no way to disable this feature currently, but you can set explicit type in watchlist: `audio:192:url` or `video:720:url`.

**Q: What format for videos? Can I change it?**  
A: Videos download as MP4 (best format for compatibility). The `--merge-output-format mp4` ensures video + audio are merged properly. To use different format, edit `--merge-output-format` in the install script.

**Q: Can I mix audio and video in the same watchlist?**  
A: Yes! The watchlist auto-detects each URL separately. You can have:
```
https://www.irozhlas.cz/podcast         # auto = audio
https://www.youtube.com/watch?v=...     # auto = video
audio:320:https://example.com           # force audio
video:1080:https://example.com          # force video
```

**Q: Does video download preserve metadata like audio?**  
A: Yes, `--embed-metadata` is included for both. Video files get title, artist (uploader), date, description, etc. embedded. Thumbnails are embedded as cover art.

---

**Built with** Bash, AppleScript, yt-dlp, and lots of ☕
