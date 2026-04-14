#!/bin/bash
# ======================================================================
#  Instalátor "yt-dlp stahovač" v2.0
#  - Download archive (nepřepisuje stažené)
#  - Historie posledních 10 URL
#  - Tlačítko "Ze souboru..." pro dávkové stahování
#  - Auto-update yt-dlp před každým stahováním
#  - macOS notifikace po dokončení
#  - Lepší pojmenování složek (series > playlist_title > uploader > Audio)
#  - Systémová Služba (pravý klik → "Stáhnout přes yt-dlp")
#  - SwiftBar menubar plugin
#  - Watchlist + týdenní LaunchAgent
# ======================================================================

set -euo pipefail

PLIST_BIN="/usr/libexec/PlistBuddy"
APP_NAME="yt-dlp stahovač"
APP_DIR="/Applications/${APP_NAME}.app"
WORKER="$APP_DIR/Contents/Resources/worker.sh"
WATCHLIST_SYNC="$APP_DIR/Contents/Resources/watchlist-sync.sh"
SERVICE_DIR="$HOME/Library/Services"
LAUNCHD_PLIST="$HOME/Library/LaunchAgents/cz.tomecek.ytdlp-watchlist.plist"
WATCHLIST_FILE="$HOME/.ytdlp_watchlist"
HISTORY_FILE="$HOME/.ytdlp_history"

if [ ! -w "/Applications" ]; then
  mkdir -p "$HOME/Applications"
  APP_DIR="$HOME/Applications/${APP_NAME}.app"
  WORKER="$APP_DIR/Contents/Resources/worker.sh"
  WATCHLIST_SYNC="$APP_DIR/Contents/Resources/watchlist-sync.sh"
fi

echo "==> Instaluji do: $APP_DIR"
rm -rf "$APP_DIR"

# ================================================================ AppleScript applet
APPLE_SRC="$(mktemp /tmp/ytdlp_applet_XXXXXX.applescript)"
cat > "$APPLE_SRC" <<'OSA'
on run
	callWorker({})
end run

on open theItems
	set argList to {}
	repeat with f in theItems
		set end of argList to POSIX path of f
	end repeat
	callWorker(argList)
end open

on callWorker(argList)
	set myPath to POSIX path of (path to me)
	set workerPath to myPath & "Contents/Resources/worker.sh"
	set cmd to quoted form of workerPath
	repeat with a in argList
		set cmd to cmd & " " & quoted form of (a as text)
	end repeat
	try
		do shell script cmd
	on error errMsg number errNum
		if errNum is not -128 then
			display dialog "Chyba workeru: " & errMsg buttons {"OK"} default button 1 with icon stop
		end if
	end try
end callWorker
OSA

echo "==> Kompiluji AppleScript applet..."
/usr/bin/osacompile -o "$APP_DIR" "$APPLE_SRC"
rm -f "$APPLE_SRC"

# Ověř executable
INFO="$APP_DIR/Contents/Info.plist"
APP_EXEC="$("$PLIST_BIN" -c "Print :CFBundleExecutable" "$INFO" 2>/dev/null || true)"
APP_BIN=""
[ -n "$APP_EXEC" ] && [ -f "$APP_DIR/Contents/MacOS/$APP_EXEC" ] \
  && APP_BIN="$APP_DIR/Contents/MacOS/$APP_EXEC"
[ -z "$APP_BIN" ] && APP_BIN="$(/usr/bin/find "$APP_DIR/Contents/MacOS" -maxdepth 1 -type f -perm -111 2>/dev/null | /usr/bin/head -n 1 || true)"
[ -z "$APP_BIN" ] && { echo "CHYBA: applet binárka nenalezena."; exit 1; }
echo "==> Applet OK: $APP_BIN"

mkdir -p "$APP_DIR/Contents/Resources"

# ================================================================ Info.plist
plist_set() {
  local key="$1" type="$2" val="$3"
  "$PLIST_BIN" -c "Set :${key} ${val}" "$INFO" 2>/dev/null \
    || "$PLIST_BIN" -c "Add :${key} ${type} ${val}" "$INFO"
}
plist_set "CFBundleName"              string "yt-dlp stahovač"
plist_set "CFBundleDisplayName"       string "yt-dlp stahovač"
plist_set "CFBundleIdentifier"        string "cz.tomecek.ytdlpstahovac"
plist_set "CFBundleShortVersionString" string "2.0"
plist_set "CFBundleVersion"           string "2.0"
plist_set "LSMinimumSystemVersion"    string "10.13"
plist_set "NSHighResolutionCapable"   bool   "true"

"$PLIST_BIN" -c "Delete :CFBundleDocumentTypes" "$INFO" 2>/dev/null || true
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes array"                             "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0 dict"                            "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string 'URL nebo textový soubor'" "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer"  "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array"        "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string public.plain-text" "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:1 string public.text"       "$INFO"
"$PLIST_BIN" -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:2 string public.url"        "$INFO"
echo "==> Info.plist OK."

# ================================================================ worker.sh
cat > "$WORKER" <<'WORKER'
#!/bin/bash
# ---- yt-dlp stahovač v2.0: worker ------------------------------------
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

OUTBASE="$HOME/Downloads/yt-dlp"
LOGFILE="$HOME/Downloads/yt-dlp-last.log"
HISTORY="$HOME/.ytdlp_history"
ARCHIVE="$HOME/Downloads/yt-dlp/.archive.txt"

# ---- notifikace ------------------------------------------------------
notify() {
  /usr/bin/osascript -e "display notification \"$1\" with title \"yt-dlp stahovač\"" >/dev/null 2>&1 || true
}

# ---- chybový dialog --------------------------------------------------
dlg_error() {
  /usr/bin/osascript -e "display dialog \"$1\" buttons {\"OK\"} default button 1 with icon stop with title \"yt-dlp stahovač\"" >/dev/null 2>&1 || true
}

# ---- kontrola závislostí --------------------------------------------
check_deps() {
  local missing=()
  command -v yt-dlp >/dev/null 2>&1 || missing+=("yt-dlp")
  command -v ffmpeg  >/dev/null 2>&1 || missing+=("ffmpeg")
  [ ${#missing[@]} -eq 0 ] && return 0

  local list="${missing[*]}"
  local has_brew="ne"; command -v brew >/dev/null 2>&1 && has_brew="ano"
  local msg="Chybí závislosti: ${list}\\n\\nHomebrew nalezen: ${has_brew}\\n\\nOtevřít Terminál s připraveným příkazem?"
  local btn
  btn=$(/usr/bin/osascript <<EOF || true
display dialog "${msg}" buttons {"Zrušit","Otevřít Terminál"} default button 2 with icon caution with title "Chybí závislosti"
EOF
  )
  if echo "$btn" | /usr/bin/grep -q "Otevřít"; then
    local cmd_file; cmd_file=$(/usr/bin/mktemp /tmp/ytdlp_install_XXXXXX.command)
    if [ "$has_brew" = "ne" ]; then
      echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' > "$cmd_file"
      echo "brew install ${list}" >> "$cmd_file"
    else
      echo "brew install ${list}" > "$cmd_file"
    fi
    chmod +x "$cmd_file"; /usr/bin/open "$cmd_file"
  fi
  exit 1
}

# ---- uložení URL do historie ----------------------------------------
save_history() {
  local url="$1"
  # Odstraň duplicity, přidej na začátek, zachovej max 10 položek
  local rest
  rest=$(grep -vxF "$url" "$HISTORY" 2>/dev/null | head -9 || true)
  printf '%s\n%s\n' "$url" "$rest" | grep -v '^$' | head -10 > "$HISTORY"
}

# ---- dialog: URL + historie + Ze souboru... -------------------------
get_url_or_file() {
  # AppleScript čte historii přímo ze souboru – bezpečnější než vkládání do heredoc
  /usr/bin/osascript <<'EOF'
on run
  set histFile to (POSIX file (POSIX path of (path to home folder) & ".ytdlp_history"))
  set histItems to {}
  try
    set histContent to read histFile
    set histLines to paragraphs of histContent
    repeat with ln in histLines
      set s to ln as string
      if length of s > 0 then set end of histItems to s
    end repeat
  end try

  -- Pokud je historie, zobraz ji jako první krok
  if (count of histItems) > 0 then
    set choices to {"— Zadat novou URL —"} & histItems
    set chosen to choose from list choices ¬
      with title "yt-dlp stahovač" ¬
      with prompt "Vyber z historie nebo zadej novou URL:" ¬
      default items {item 1 of choices} ¬
      OK button name "Použít" cancel button name "Zrušit"
    if chosen is false then return ""
    set sel to item 1 of chosen
    if sel is not "— Zadat novou URL —" then return sel
  end if

  -- Dialog pro ruční zadání URL
  set clipRaw to do shell script "pbpaste | head -1 | tr -d '\\r\\n' 2>/dev/null || true"
  if clipRaw does not start with "http" then set clipRaw to ""
  try
    set dlg to display dialog "Zadej URL stránky pro stažení audia:" ¬
      default answer clipRaw ¬
      buttons {"Zrušit", "Ze souboru…", "Stáhnout"} ¬
      default button 3 ¬
      with title "yt-dlp stahovač"
    if button returned of dlg is "Zrušit" then return ""
    if button returned of dlg is "Ze souboru…" then
      set f to choose file with prompt "Vyber .txt soubor se seznamem URL (jedna URL na řádek):" ¬
        of type {"public.plain-text"}
      return "FILE:" & POSIX path of f
    end if
    return text returned of dlg
  on error number -128
    return ""
  end try
end run
EOF
}

# ---- detekce typu zdroje (audio vs. video) --------------------------
detect_source_type() {
  local url="$1"
  # Audio sources (ČRo a podobné)
  if echo "$url" | /usr/bin/grep -Eiq "(rozhlas|radi[o]|podcast|spotify|soundcloud|anchor)"; then
    echo "audio"
    return
  fi
  # Video sources
  if echo "$url" | /usr/bin/grep -Eiq "(youtube|youtu\.be|facebook|fb\.com|x\.com|twitter|tiktok|instagram|vimeo|bluesky|twitch|rumble)"; then
    echo "video"
    return
  fi
  # Default pro neznámé
  echo "unknown"
}

# ---- dialog: potvrzení typu (audio / video) -------------------------
get_media_type() {
  local url="$1"
  local detected="$2"

  local prompt_text="Typ obsahu:"
  case "$detected" in
    audio)  prompt_text="Detekován audio podcast. Chceš audio nebo video?" ;;
    video)  prompt_text="Detekován video obsah. Chceš video nebo audio?" ;;
    *)      prompt_text="Jaký typ obsahu chceš stáhnout?" ;;
  esac

  # Urči defaultní tlačítko (1 = Audio, 2 = Video)
  local default_btn=1
  [ "$detected" = "video" ] && default_btn=2

  /usr/bin/osascript <<EOF
set result to button returned of (display dialog "$prompt_text" ¬
  buttons {"Audio (MP3)", "Video (MP4)"} ¬
  default button $default_btn ¬
  with title "yt-dlp stahovač")
if result = "Audio (MP3)" then
  return "audio"
else
  return "video"
end if
EOF
}

# ---- dialog: výběr kvality – AUDIO ----------------------------------
get_audio_quality() {
  /usr/bin/osascript <<'EOF'
set opts to {"192 kbps (doporučeno)", "128 kbps", "320 kbps"}
set chosen to choose from list opts ¬
  with title "Kvalita MP3" ¬
  with prompt "Vyber bitrate výsledného MP3:" ¬
  default items {"192 kbps (doporučeno)"}
if chosen is false then return ""
set q to item 1 of chosen
if q starts with "128" then return "128"
if q starts with "320" then return "320"
return "192"
EOF
}

# ---- dialog: výběr kvality – VIDEO ---------------------------------
get_video_quality() {
  /usr/bin/osascript <<'EOF'
set opts to {"1080p (best)", "720p (doporučeno)", "480p", "360p (nejmenší)"}
set chosen to choose from list opts ¬
  with title "Kvalita videa" ¬
  with prompt "Vyber rozlišení videa:" ¬
  default items {"720p (doporučeno)"}
if chosen is false then return ""
set q to item 1 of chosen
if q starts with "1080" then return "1080"
if q starts with "720" then return "720"
if q starts with "480" then return "480"
return "360"
EOF
}

# ---- spuštění yt-dlp ve viditelném Terminálu ------------------------
run_download() {
  local url="$1" media_type="$2" quality="$3"
  mkdir -p "$OUTBASE"

  # Šablona: series má přednost (ČRo pořady), pak playlist_title, pak uploader
  local template='%(series,playlist_title,uploader|Obsah)s/%(playlist_index,autonumber)02d - %(title)s.%(ext)s'

  local tmp; tmp=$(/usr/bin/mktemp /tmp/ytdlp_run_XXXXXX.command)

  # Vyber odpovídající yt-dlp příkaz dle typu
  local ytdlp_cmd=""
  local quality_desc=""

  if [ "$media_type" = "audio" ]; then
    ytdlp_cmd="yt-dlp \\
  -f bestaudio \\
  --extract-audio --audio-format mp3 --audio-quality ${quality}K \\
  --embed-metadata --embed-thumbnail --add-metadata \\
  --no-mtime --no-overwrites \\
  --download-archive \"\${ARCHIVE}\" \\
  -o \"\${template}\" \\\\"
    quality_desc="${quality} kbps MP3"
  else
    # Video: vyber nejlepší video do zadané výšky + audio a slučuj
    local format_spec="bv[height<=${quality}]+ba/b[height<=${quality}]"
    ytdlp_cmd="yt-dlp \\
  -f \"$format_spec\" \\
  --merge-output-format mp4 \\
  --embed-metadata \\
  --no-mtime --no-overwrites \\
  --download-archive \"\${ARCHIVE}\" \\
  -o \"\${template}\" \\\\"
    quality_desc="${quality}p (best MP4)"
  fi

  cat > "$tmp" <<EOF
#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"
cd "${OUTBASE}" || exit 1
clear
echo "========================================================="
echo " yt-dlp stahovač ($([ "$media_type" = "audio" ] && echo "AUDIO" || echo "VIDEO"))"
echo " URL:     ${url}"
echo " Kvalita: ${quality_desc}"
echo " Cíl:     ${OUTBASE}/"
echo "========================================================="
echo
# --- auto-update yt-dlp (tiše na pozadí) ---
echo "[aktualizuji yt-dlp...]"
yt-dlp -U --quiet 2>&1 | grep -v "^$" || true
echo
# --- stahování ---
${ytdlp_cmd}
  "${url}" 2>&1 | tee "${LOGFILE}"
RC=\${PIPESTATUS[0]}
echo
if [ "\$RC" = "0" ]; then
  echo "=== HOTOVO ==="
  /usr/bin/osascript -e 'display notification "Stahování dokončeno ✓" with title "yt-dlp stahovač"' >/dev/null 2>&1 || true
  /usr/bin/open "${OUTBASE}"
else
  echo "=== CHYBA (kód \$RC) – viz log: ${LOGFILE} ==="
  echo "--- Posledních 20 řádků logu: ---"
  tail -20 "${LOGFILE}"
  /usr/bin/osascript -e 'display notification "Stahování selhalo – viz Terminál" with title "yt-dlp stahovač"' >/dev/null 2>&1 || true
fi
echo
echo "Toto okno Terminálu můžeš zavřít  (Cmd + W)."
rm -f "${tmp}"
EOF
  chmod +x "$tmp"
  /usr/bin/open "$tmp"
}

# ================================================================ MAIN
check_deps

URLS=()

if [ "$#" -gt 0 ]; then
  # Argumenty z drag-drop nebo Systémové Služby
  for arg in "$@"; do
    if [ -f "$arg" ]; then
      while IFS= read -r line || [ -n "$line" ]; do
        line="$(echo "$line" | /usr/bin/tr -d '\r' | /usr/bin/awk '{$1=$1;print}')"
        case "$line" in ""|\#*) ;; http*) URLS+=("$line") ;; esac
      done < "$arg"
    else
      URLS+=("$arg")
    fi
  done
else
  # Interaktivní dialog
  RESULT=$(get_url_or_file)
  [ -z "$RESULT" ] && exit 0

  if [[ "$RESULT" == FILE:* ]]; then
    txt="${RESULT#FILE:}"
    while IFS= read -r line || [ -n "$line" ]; do
      line="$(echo "$line" | /usr/bin/tr -d '\r' | /usr/bin/awk '{$1=$1;print}')"
      case "$line" in ""|\#*) ;; http*) URLS+=("$line") ;; esac
    done < "$txt"
  else
    URLS+=("$RESULT")
  fi
fi

[ ${#URLS[@]} -eq 0 ] && { dlg_error "Nenalezeno žádné URL."; exit 1; }

# Pokud je víc URL, zeptej se na typ JEDENKRÁT pro všechny (pokud jsou stejného typu)
# Jinak zeptej se pro každou URL zvlášť
MEDIA_TYPE=""
QUALITY=""

if [ ${#URLS[@]} -eq 1 ]; then
  # Jedna URL: detekuj a zeptej se
  DETECTED=$( detect_source_type "${URLS[0]}" )
  MEDIA_TYPE=$( get_media_type "${URLS[0]}" "$DETECTED" )
  [ -z "$MEDIA_TYPE" ] && exit 0

  if [ "$MEDIA_TYPE" = "audio" ]; then
    QUALITY=$( get_audio_quality )
  else
    QUALITY=$( get_video_quality )
  fi
  [ -z "$QUALITY" ] && exit 0

  save_history "${URLS[0]}"
  run_download "${URLS[0]}" "$MEDIA_TYPE" "$QUALITY"
else
  # Víc URL: zeptej se pro každou zvlášť
  for u in "${URLS[@]}"; do
    DETECTED=$( detect_source_type "$u" )
    MEDIA_TYPE=$( get_media_type "$u" "$DETECTED" )
    [ -z "$MEDIA_TYPE" ] && continue

    if [ "$MEDIA_TYPE" = "audio" ]; then
      QUALITY=$( get_audio_quality )
    else
      QUALITY=$( get_video_quality )
    fi
    [ -z "$QUALITY" ] && continue

    save_history "$u"
    run_download "$u" "$MEDIA_TYPE" "$QUALITY"
  done
fi
WORKER
chmod +x "$WORKER"

# ================================================================ watchlist-sync.sh
cat > "$WATCHLIST_SYNC" <<'SYNC'
#!/bin/bash
# ---- yt-dlp stahovač: Watchlist synchronizace -----------------------
# Volán týdenně přes LaunchAgent.
# Číte ~/.ytdlp_watchlist, formát:
#   https://example.com/show          (auto-detect typ, default kvalita)
#   audio:192:https://example.com     (audio, 192 kbps)
#   video:720:https://example.com     (video, 720p)
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WATCHLIST="$HOME/.ytdlp_watchlist"
OUTBASE="$HOME/Downloads/yt-dlp"
ARCHIVE="$HOME/Downloads/yt-dlp/.archive.txt"
LOGFILE="$HOME/Downloads/yt-dlp-watchlist.log"

# --- detekce typu zdroje ---
detect_source_type() {
  local url="$1"
  if echo "$url" | grep -Eiq "(rozhlas|radi[o]|podcast|spotify|soundcloud)"; then
    echo "audio"
  elif echo "$url" | grep -Eiq "(youtube|youtu\.be|facebook|fb\.com|x\.com|twitter|tiktok|instagram|vimeo|bluesky|twitch)"; then
    echo "video"
  else
    echo "audio"  # default
  fi
}

[ -f "$WATCHLIST" ] || exit 0
command -v yt-dlp >/dev/null 2>&1 || exit 1

mkdir -p "$OUTBASE"
echo "=== Watchlist sync: $(date) ===" >> "$LOGFILE"

# Auto-update
yt-dlp -U --quiet 2>/dev/null || true

while IFS= read -r line || [ -n "$line" ]; do
  line="$(echo "$line" | tr -d '\r' | awk '{$1=$1;print}')"
  case "$line" in ""|\#*) continue ;; esac

  # Parse: [type:][quality:]url
  media_type=""
  quality=""
  url="$line"

  # Pokud začíná "audio:" nebo "video:"
  if [[ "$line" =~ ^(audio|video):(.+)$ ]]; then
    media_type="${BASH_REMATCH[1]}"
    line="${BASH_REMATCH[2]}"
  fi

  # Pokud zbývá "number:" (kvalita)
  if [[ "$line" =~ ^([0-9]+):(.+)$ ]]; then
    quality="${BASH_REMATCH[1]}"
    url="${BASH_REMATCH[2]}"
  else
    url="$line"
  fi

  # Pokud není typ určen, detekuj
  if [ -z "$media_type" ]; then
    media_type=$( detect_source_type "$url" )
  fi

  # Výchozí kvalita podle typu
  if [ -z "$quality" ]; then
    [ "$media_type" = "audio" ] && quality="192" || quality="720"
  fi

  echo "[$(date +%H:%M)] $media_type | $quality | $url" | tee -a "$LOGFILE"

  # --- yt-dlp příkaz podle typu ---
  if [ "$media_type" = "audio" ]; then
    yt-dlp \
      -f bestaudio \
      --extract-audio --audio-format mp3 --audio-quality "${quality}K" \
      --embed-metadata --embed-thumbnail --add-metadata \
      --no-mtime --no-overwrites \
      --download-archive "$ARCHIVE" \
      -o '%(series,playlist_title,uploader|Watchlist)s/%(playlist_index,autonumber)02d - %(title)s.%(ext)s' \
      "$url" >> "$LOGFILE" 2>&1 || true
  else
    # Video: formát podle zadané výšky
    local format_spec="bv[height<=${quality}]+ba/b[height<=${quality}]"
    yt-dlp \
      -f "$format_spec" \
      --merge-output-format mp4 \
      --embed-metadata \
      --no-mtime --no-overwrites \
      --download-archive "$ARCHIVE" \
      -o '%(series,playlist_title,uploader|Watchlist)s/%(playlist_index,autonumber)02d - %(title)s.%(ext)s' \
      "$url" >> "$LOGFILE" 2>&1 || true
  fi

done < "$WATCHLIST"

echo "=== Hotovo ===" >> "$LOGFILE"
/usr/bin/osascript -e 'display notification "Watchlist synchronizace dokončena" with title "yt-dlp stahovač"' >/dev/null 2>&1 || true
SYNC
chmod +x "$WATCHLIST_SYNC"

# ================================================================ Výchozí watchlist (pokud neexistuje)
if [ ! -f "$WATCHLIST_FILE" ]; then
  cat > "$WATCHLIST_FILE" <<'WL'
# yt-dlp Watchlist – sledované pořady
# Formát: [[typ:]kvalita:]URL
# typ: audio (default pro rozhlas), video (default pro YouTube/FB/TikTok/...)
# kvalita: pro audio = kbps (128/192/320), pro video = výška v px (360/480/720/1080)
#
# Příklady:
#   https://www.irozhlas.cz/prehled-zprav-irozhlas-podcast
#   audio:320:https://www.mujrozhlas.cz/prehled-zprav
#   video:720:https://www.youtube.com/user/example
#   video:1080:https://www.facebook.com/page/videos
#
# Přidej sem URL svých oblíbených pořadů a videí.
# Každé pondělí v 8:00 se automaticky stáhnou nové epizody.
WL
  echo "==> Watchlist vytvořen: $WATCHLIST_FILE"
fi

# ================================================================ LaunchAgent (týdenní watchlist)
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCHD_PLIST" <<LAUNCHD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>cz.tomecek.ytdlp-watchlist</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${WATCHLIST_SYNC}</string>
  </array>
  <!-- Každé pondělí v 8:00 -->
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>1</integer>
    <key>Hour</key><integer>8</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>$HOME/Downloads/yt-dlp-watchlist.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/Downloads/yt-dlp-watchlist.log</string>
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
LAUNCHD

# Načti/přenačti LaunchAgent
/bin/launchctl unload "$LAUNCHD_PLIST" 2>/dev/null || true
/bin/launchctl load "$LAUNCHD_PLIST"
echo "==> LaunchAgent (watchlist) OK."

# ================================================================ Systémová Služba
mkdir -p "${SERVICE_DIR}/Stáhnout přes yt-dlp.workflow/Contents"
cat > "${SERVICE_DIR}/Stáhnout přes yt-dlp.workflow/Contents/document.wflow" <<WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key><string>521.1</string>
  <key>AMApplicationVersion</key><string>2.10</string>
  <key>AMDocumentVersion</key><string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>AMAccepts</key>
        <dict>
          <key>Container</key><string>List</string>
          <key>Optional</key><true/>
          <key>Types</key><array><string>com.apple.cocoa.string</string></array>
        </dict>
        <key>AMActionVersion</key><string>2.0.3</string>
        <key>AMApplication</key><array><string>Automator</string></array>
        <key>AMParameterProperties</key>
        <dict>
          <key>COMMAND_STRING</key><dict/>
          <key>CheckedForUserDefaultShell</key><dict/>
          <key>inputMethod</key><dict/>
          <key>shell</key><dict/>
          <key>source</key><dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key><string>List</string>
          <key>Types</key><array><string>com.apple.cocoa.string</string></array>
        </dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key><string>Run Shell Script</string>
        <key>ActionParameters</key>
        <dict>
          <key>COMMAND_STRING</key>
          <string>export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"
URL=\$(echo "\$@" | tr -d '\\n\\r' | xargs)
if echo "\$URL" | grep -Eq '^https?://'; then
  '${WORKER}' "\$URL" &
fi</string>
          <key>CheckedForUserDefaultShell</key><true/>
          <key>inputMethod</key><integer>1</integer>
          <key>shell</key><string>/bin/bash</string>
          <key>source</key><string></string>
        </dict>
        <key>BundleIdentifier</key><string>com.apple.automator.runshellscript</string>
        <key>CFBundleVersion</key><string>2.0.3</string>
        <key>CanShowSelectedItemsWhenRun</key><false/>
        <key>CanShowWhenRun</key><true/>
        <key>Category</key><array><string>AMCategoryUtilities</string></array>
        <key>Class Name</key><string>RunShellScriptAction</string>
        <key>InputUUID</key><string>A1B2C3D4-0001-0001-0001-000000000001</string>
        <key>Keywords</key><array><string>Shell</string><string>Script</string></array>
        <key>OutputUUID</key><string>A1B2C3D4-0001-0001-0001-000000000002</string>
        <key>UUID</key><string>A1B2C3D4-0001-0001-0001-000000000003</string>
        <key>UnlocalizedApplications</key><array><string>Automator</string></array>
        <key>arguments</key>
        <dict>
          <key>0</key><dict>
            <key>default value</key><integer>0</integer>
            <key>name</key><string>inputMethod</string>
            <key>required</key><string>0</string>
            <key>type</key><string>0</string>
            <key>uuid</key><string>0</string>
          </dict>
          <key>1</key><dict>
            <key>default value</key><string></string>
            <key>name</key><string>source</string>
            <key>required</key><string>0</string>
            <key>type</key><string>0</string>
            <key>uuid</key><string>1</string>
          </dict>
          <key>2</key><dict>
            <key>default value</key><string></string>
            <key>name</key><string>COMMAND_STRING</key>
            <key>required</key><string>0</string>
            <key>type</key><string>0</string>
            <key>uuid</key><string>2</string>
          </dict>
          <key>3</key><dict>
            <key>default value</key><string>/bin/bash</string>
            <key>name</key><string>shell</string>
            <key>required</key><string>0</string>
            <key>type</key><string>0</string>
            <key>uuid</key><string>3</string>
          </dict>
          <key>4</key><dict>
            <key>default value</key><false/>
            <key>name</key><string>CheckedForUserDefaultShell</string>
            <key>required</key><string>0</string>
            <key>type</key><string>0</string>
            <key>uuid</key><string>4</string>
          </dict>
        </dict>
        <key>isViewVisible</key><true/>
        <key>location</key><string>309.000000:253.000000</string>
        <key>nibPath</key>
        <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/en.lproj/main.nib</string>
      </dict>
      <key>isViewVisible</key><true/>
    </dict>
  </array>
  <key>connectors</key><dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.Automator.text</string>
    <key>serviceOutputTypeIdentifier</key>
    <string>com.apple.Automator.nothing</string>
    <key>serviceProcessesInput</key><integer>0</integer>
    <key>systemImageName</key><string>NSActionTemplate</string>
    <key>workflowTypeIdentifier</key>
    <string>com.apple.Automator.servicesMenu</string>
  </dict>
</dict>
</plist>
WFLOW

# Oznám systému novou Službu
/System/Library/CoreServices/pbs -update 2>/dev/null || true
echo "==> Systémová Služba OK: ${SERVICE_DIR}/Stáhnout přes yt-dlp.workflow"

# ================================================================ SwiftBar plugin
install_swiftbar_plugin() {
  local plugin_dir=""
  # Zkus najít SwiftBar nebo xbar
  if [ -d "$HOME/Library/Application Support/SwiftBar" ]; then
    plugin_dir="$HOME/Library/Application Support/SwiftBar/Plugins"
  elif [ -d "$HOME/Library/Application Support/xbar/plugins" ]; then
    plugin_dir="$HOME/Library/Application Support/xbar/plugins"
  fi

  if [ -z "$plugin_dir" ]; then
    echo "==> SwiftBar/xbar nenalezen – plugin uložen do: $APP_DIR/Contents/Resources/swiftbar-plugin.sh"
    echo "    Nainstaluj SwiftBar: brew install --cask swiftbar"
    echo "    Pak zkopíruj plugin do složky SwiftBar Plugins."
    plugin_dir="$APP_DIR/Contents/Resources"
    local plugin_file="$plugin_dir/swiftbar-plugin.sh"
    write_swiftbar_plugin "$plugin_file"
    return
  fi

  mkdir -p "$plugin_dir"
  local plugin_file="$plugin_dir/yt-dlp.1h.sh"   # refresh každou hodinu
  write_swiftbar_plugin "$plugin_file"
  echo "==> SwiftBar plugin OK: $plugin_file"
}

write_swiftbar_plugin() {
  local f="$1"
  cat > "$f" <<SWIFTBAR
#!/bin/bash
# yt-dlp stahovač – SwiftBar / xbar menubar plugin
# refresh: 1h (název souboru: yt-dlp.1h.sh)
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\$PATH"
WORKER='${WORKER}'
OUTBASE="\$HOME/Downloads/yt-dlp"
WATCHLIST_SYNC='${WATCHLIST_SYNC}'

# --- Menubar ikona + název ---
echo "⬇ yt-dlp"
echo "---"
echo "Stáhnout audio… | bash='\$WORKER' terminal=false"
echo "---"
echo "Watchlist sync nyní | bash='\$WATCHLIST_SYNC' terminal=true"
echo "Upravit Watchlist | bash=/usr/bin/open param1='\$HOME/.ytdlp_watchlist' terminal=false"
echo "---"
echo "Otevřít stažené | bash=/usr/bin/open param1='\$OUTBASE' terminal=false"
echo "Zobrazit poslední log | bash=/usr/bin/open param1='\$HOME/Downloads/yt-dlp-last.log' terminal=false"
echo "---"
# Počet stažených souborů
COUNT=\$(find "\$OUTBASE" -name "*.mp3" 2>/dev/null | wc -l | tr -d ' ')
echo "Staženo MP3: \${COUNT} | color=#888888"
SWIFTBAR
  chmod +x "$f"
}

install_swiftbar_plugin

# ================================================================ Refresh Finder
/usr/bin/touch "$APP_DIR"

echo
echo "=========================================================="
echo " HOTOVO. Nainstalováno:"
echo "   App:      ${APP_DIR}"
echo "   Služba:   Systémové předvolby → Klávesnice → Služby"
echo "             (nebo pravý klik na vybraný text)"
echo "   Watchlist: ${WATCHLIST_FILE}"
echo "   LaunchAgent: každé pondělí v 8:00"
echo
echo " Pokud používáš SwiftBar, přidej do složky Plugins:"
echo "   ${APP_DIR}/Contents/Resources/swiftbar-plugin.sh"
echo
echo " Výstup:    ~/Downloads/yt-dlp/<nazev poradu>/"
echo " Archive:   ~/Downloads/yt-dlp/.archive.txt"
echo " Log:       ~/Downloads/yt-dlp-last.log"
echo "=========================================================="

printf "Spustit aplikaci teď? [y/N] "
read -r ans || true
case "${ans:-}" in
  y|Y|a|A) /usr/bin/open "$APP_DIR" ;;
esac
