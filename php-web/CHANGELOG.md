# Changelog - yt-dlp Stahovač PHP

Všechny podstatné změny v tomto projektu budou zaznamenány v tomto souboru.

## [1.0.0] - 2026-04-14

### ✨ Features

#### Core Functionality
- ✅ Webová aplikace pro stahování videa a zvuku z webových stránek
- ✅ Automatická detekce typu obsahu (video vs audio)
- ✅ Výběr kvality pro video (1080p, 720p, 480p, 360p)
- ✅ Výběr bitrate pro zvuk (320, 192, 128 kbps)
- ✅ AJAX polling pro status stahování (bez refreshu stránky)

#### Supported Platforms
- **Video:** YouTube, Facebook, TikTok, Instagram, Vimeo, Reddit, Twitch, Bluesky, Rumble, Odysee, DailyMotion
- **Audio:** Spotify, SoundCloud, Rozhlas.cz, Podcasts, Bandcamp, Deezer

#### UI/UX
- 🎨 Moderní Bootstrap 5 design
- 📱 Responsive design (mobile + desktop)
- ⚡ Real-time status feedback
- 🎯 Jednoduchý jednostránkový formulář
- 🔐 Bez přihlašování (anonymní)

#### Backend
- 🗄️ SQLite3 databáze pro historii stahování
- 📊 Download history tracking (URL, filename, quality, status)
- 🔄 Asynchronní polling systém
- 🛡️ Input validation a escapování
- 🚀 Optimalizováno pro shared hosting

#### Security
- ✅ .htaccess ochrána na `data/` a `temp/` adresáře
- ✅ Všechny vstupy jsou validovány
- ✅ Prevence path traversal
- ✅ SQL injection ochrána (prepared statements)
- ✅ Cross-site scripting (XSS) prevention

#### Files
- `index.php` - Hlavní aplikace + frontend
- `download.php` - Backend pro stahování
- `status.php` - Polling pro status
- `.htaccess` - Bezpečnost a optimalizace
- `setup.sh` - Automatická inicializace
- `README.md` - Dokumentace
- `DEPLOYMENT.md` - Návod pro nasazení

### 🔧 Technical Details

#### Technology Stack
- **Backend:** PHP 8.2+
- **Database:** SQLite3
- **Frontend:** HTML5, CSS3, Vanilla JavaScript
- **UI Framework:** Bootstrap 5.3
- **Server:** Apache (aerohosting.cz)

#### System Requirements
- PHP 8.2+
- SQLite3 extension
- yt-dlp command-line tool
- Apache with mod_rewrite (pro .htaccess)
- 500+ MB disk space

#### Configuration
- Max execution time: 300s
- Post max size: 500 MB
- Memory limit: 256 MB
- Upload max: 500 MB

### 📝 Directory Structure

```
php-web/
├── index.php              # Hlavní aplikace
├── download.php           # Backend - stahování
├── status.php             # Backend - status
├── .htaccess              # Bezpečnost
├── .gitignore             # Git ignore
├── setup.sh               # Setup skript
├── README.md              # Dokumentace
├── DEPLOYMENT.md          # Návod nasazení
├── CHANGELOG.md           # Tento soubor
├── downloads/             # Stažené soubory (vytvořeno)
├── temp/                  # Dočasné soubory (vytvořeno)
└── data/
    └── history.db         # SQLite databáze (vytvořeno)
```

### 🎯 Design Decisions

#### 1. Synchronní vs Asynchronní Stahování
**Volba:** Synchronní (blokující)

**Důvod:** Na shared hostingu (aerohosting.cz) nejde spustit background procesy. Aplikace spustí yt-dlp synchronně v PHP procesu. Pro dlouhá stahování se vrátí výsledek ve chvíli, kdy se soubor stáhne.

**Alternativa:** Asynchronní queue (Redis/RabbitMQ) - příliš složité pro shared hosting

#### 2. JavaScript Framework
**Volba:** Vanilla JavaScript bez frameworku

**Důvod:** Minimální závislosti, lepší výkon, jednodušší nasazení. Bootstrap 5 postačuje pro UI.

**Alternativa:** React/Vue - overkill pro jednoduchou aplikaci

#### 3. SQLite vs MySQL
**Volba:** SQLite3

**Důvod:** 
- Žádný server pro správu
- Funguje na shared hostingu
- Dostatečné pro 5-10 uživatelů
- Nižší overhead

**Alternativa:** MySQL/MariaDB - není potřeba

#### 4. AJAX Polling vs WebSockets
**Volba:** AJAX Polling (1 sekunda interval)

**Důvod:**
- Kompatibilita se shared hostingem
- Jednodušší implementace
- Stačí pro naši use-case

**Alternativa:** WebSockets - nemusí být podporovány na aerohosting.cz

### 🐛 Known Issues

Zatím žádné známé problémy. (v1.0.0)

### 🔄 Future Improvements

Pro v2.0+:

- [ ] Playlist support (stahování více videí najednou)
- [ ] Subtitle extraction
- [ ] Format conversion (MP4 → WebM, atd.)
- [ ] Download acceleration (multiple streams)
- [ ] Web interface pro správu history
- [ ] Email notifications na dokončení
- [ ] Compression (ZIP archiv pro více souborů)
- [ ] Docker image pro easy deployment
- [ ] Admin panel pro monitoring
- [ ] Rate limiting a quota

### 🚀 Version History

| Verze | Datum | Status |
|-------|-------|--------|
| 1.0.0 | 2026-04-14 | ✅ Released |
| 2.0.0 | TBD | 🔄 Planned |

### 📖 Migration Notes

Aplikace je nová (v1.0), není potřeba migrace z předchozí verze.

### 📞 Feedback

Pro feedback, feature requests, nebo bugreports:
1. Zkontroluj README.md - řešení problémů
2. Kontaktuj support aerohosting.cz (pro problémy se serverem)
3. Vytvoř GitHub issue (pokud máš přístup k repozitáři)

---

**Format:** Toto je changelog pro https://keepachangelog.com/
