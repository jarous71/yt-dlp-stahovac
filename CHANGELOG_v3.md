# yt-dlp stahovač v3.0 – Video Support Update

## Co je nového

### 🎬 Video Support
- **Auto-detects content type** – audio podcasts vs. video obsah
- **Smart dialogs** – different quality options for audio (128/192/320 kbps) vs. video (1080p/720p/480p/360p)
- **Works with 15+ platforms** – YouTube, Facebook, TikTok, Instagram, Vimeo, Bluesky, Twitch, X/Twitter, Reddit, Bandcamp a dalších
- **MP4 video format** – videos stahuje v MP4 s embedded metadaty (title, thumbnail, artist)

### 🤖 Smart Auto-Detection
App automaticky pozná, co stahuje:

```
Audio sources (default audio):
  ✓ Český rozhlas – všechny stanice
  ✓ Podcasts (Spotify, Apple, Anchor...)
  ✓ SoundCloud, Bandcamp

Video sources (default video):
  ✓ YouTube, Vimeo
  ✓ Facebook, Instagram
  ✓ TikTok, X/Twitter
  ✓ Bluesky, Twitch, Reddit
  ✓ A další...
```

Uživatel **vždy vidí detekovaný typ a může ho změnit** před stahováním.

### 🎯 Watchlist se smíšeným obsahem
Stejný watchlist teď zvládá audio i video:

```
# ~/.ytdlp_watchlist

# Audio podcasts
https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
audio:320:https://www.mujrozhlas.cz/zaznamy

# Video
video:720:https://www.youtube.com/@channel
https://www.facebook.com/page/videos          # auto-detect

# Explicitní specifikace
audio:192:https://example.com/podcast
video:1080:https://example.com/video
```

Watchlist sync (každé pondělí v 8:00) automaticky pozná typ a stáhne vhodným formátem.

## Jak to funguje

### 1. Dialog na výběr typu
```
User: https://www.youtube.com/...
App:  "Detekován video obsah. Chceš video nebo audio?"
```

### 2. Kvalita podle typu
```
AUDIO:
  [x] 192 kbps (doporučeno)
  [ ] 128 kbps
  [ ] 320 kbps

VIDEO:
  [x] 720p (doporučeno)
  [ ] 1080p
  [ ] 480p
  [ ] 360p
```

### 3. yt-dlp příkazy
```bash
# Audio
yt-dlp -f bestaudio --extract-audio --audio-format mp3 \
  --audio-quality 192K --embed-metadata ...

# Video
yt-dlp -f "bv[height<=720]+ba/b[height<=720]" \
  --merge-output-format mp4 --embed-metadata ...
```

## Instalace v3.0

```bash
bash install-ytdlp-stahovac.sh
```

Skript rozpozná, že máš nainstalovanou starší verzi, a aktualizuje ji.

## Backward Compatibility

✅ **Všechno co fungovalo v v2.0, funguje dál:**
- URL history
- Download archive
- Watchlist (+ nové formáty)
- Systémová Služba
- SwiftBar plugin
- LaunchAgent

Existující watchlist z v2.0 bude fungovat, jen se přidá auto-detekce videí.

## Příklady

### Stažení videa z YouTube
```
1. Aplikace
2. URL: https://www.youtube.com/watch?v=...
3. App: "Detekován video obsah. Video nebo audio?"
4. Vyberu: Video
5. App: "Vyber rozlišení: 1080p/720p/480p/360p?"
6. Vyberu: 720p
7. Stahuje: video_720p.mp4
```

### Stažení podcastu (jako předtím)
```
1. Aplikace
2. URL: https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
3. App: "Detekován audio podcast. Audio nebo video?"
4. Vyberu: Audio
5. App: "Vyber kvalitu: 128/192/320 kbps?"
6. Vyberu: 192 kbps (default)
7. Stahuje: 01 - Prehled zprav.mp3
```

### Watchlist se smíšeným obsahem (nové)
```yaml
# ~/.ytdlp_watchlist

# Moje podcasty – budou staženy jako audio
https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
https://www.mujrozhlas.cz/osobnost-dne

# Moje videa – budou stažena jako MP4
https://www.youtube.com/@My_Channel
video:1080:https://www.facebook.com/my_videos

# Explicitní nastavení
audio:320:https://example.com/podcast      # force audio, 320 kbps
video:480:https://example.com/videos       # force video, 480p
```

**Každé pondělí v 8:00** se automaticky stáhnou:
- Nové epizody podcastů (MP3)
- Nová videa (MP4)

## Co se změnilo v kódu

- **worker.sh**: Added `detect_source_type()`, `get_media_type()`, `get_video_quality()`
- **run_download()**: Now takes 3 params (url, media_type, quality) instead of 2
- **watchlist-sync.sh**: Enhanced format parsing, supports audio/video prefixes
- **README.md**: Updated documentation with auto-detection, video examples, FAQ

## Testing

```bash
# Syntax check
bash -n install-ytdlp-stahovac.sh

# Install
bash install-ytdlp-stahovac.sh

# Test auto-detection
# Audio: https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
# Video: https://www.youtube.com/watch?v=dQw4w9WgXcQ
```

## Future Ideas

- [ ] Custom quality profiles (Low/Medium/High presets)
- [ ] Playlist download optimization
- [ ] Format conversion (WebM, AV1 for video)
- [ ] Subtitle download option for videos
- [ ] Video thumbnail extraction
- [ ] Batch format conversion post-download

## Migration from v2.0

1. **Backup** (optional): `cp -r ~/Downloads/yt-dlp ~/Downloads/yt-dlp.backup`
2. **Run installer**: `bash install-ytdlp-stahovac.sh`
3. **Existing files** preserved – .archive.txt, history, settings
4. **Watchlist** backwards compatible – old format still works, new features available

## Support

- 🐛 **Bug reports**: Open issue on GitHub
- 💡 **Feature requests**: GitHub discussions
- 📖 **Documentation**: See README.md, CHANGELOG_v3.md
