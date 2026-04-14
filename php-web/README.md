# yt-dlp Stahovač - PHP 8.2 Web Aplikace

Jednoduchá webová aplikace pro stahování audio a video obsahu z webových stránek. Určeno pro **aerohosting.cz** s PHP 8.2 na sdíleném hostingu.

## 📋 Požadavky

- **PHP 8.2+** (aerohosting.cz)
- **yt-dlp** nainstalovaný na serveru (kontaktovat supportu aerohosting.cz)
- **SQLite3 extension** pro PHP (obvykle aktivní)
- Minimálně **500 MB** diskového prostoru (pro stahování)
- Subdoména na vaší doméně

## 🚀 Instalace

### 1. Upload na server

1. Vytvořte na aerohosting.cz subdománu (např. `download.vasdomena.cz`)
2. Nahrajte všechny soubory přes FTP/SFTP do kořene subdomény:
   ```
   /php-web/
   ├── index.php
   ├── download.php
   ├── status.php
   ├── .htaccess
   ├── downloads/        (criar, chmod 755)
   ├── temp/             (criar, chmod 755)
   └── data/             (criar, chmod 755)
   ```

### 2. Příprrava adresářů

Přes FTP vytvořte prázdné adresáře a nastavte permisíí:
- `downloads/` - pro stažené soubory
- `temp/` - pro dočasné soubory
- `data/` - pro SQLite databázi

```bash
chmod 755 downloads temp data
```

### 3. Ověření instalace

Navštívit: `https://download.vasdomena.cz/` (namíst `download.vasdomena.cz`)

Pokud se zobrazí chyba "yt-dlp není dostupný", kontaktujte support aerohosting.cz s žádostí o instalaci yt-dlp.

## 📱 Jak používat

### Stahování videa

1. Zadej URL videa (YouTube, Facebook, TikTok, Vimeo, atd.)
2. Vyber kvalitu (1080p, 720p, 480p, 360p)
3. Klikni "📥 Stáhnout"
4. Soubor se stáhne automaticky

### Stahování zvuku

1. Zadej URL audiní stránky (Spotify, SoundCloud, Rozhlas.cz, atd.)
2. Vyber bitrate (320, 192, 128 kbps)
3. Klikni "📥 Stáhnout"
4. MP3 se stáhne automaticky

## 🎯 Podporované platformy

### 📹 Video
- YouTube, youtu.be
- Facebook, fb.watch
- TikTok, vm.tiktok
- Instagram
- Vimeo
- Reddit
- Twitch
- Bluesky
- Rumble
- Odysee (LBRY)
- DailyMotion

### 🎵 Audio
- Spotify
- SoundCloud
- Rozhlas.cz (všechny ČRo stanice)
- Podcasts
- Bandcamp
- Deezer

## ⚙️ Konfigurece

### Download kvalita

**Video:**
- 1080p - Full HD (největší soubor)
- 720p - HD (doporučeno) ⭐
- 480p - menší soubor
- 360p - nejmenší soubor

**Audio:**
- 320 kbps - nejlepší kvalita
- 192 kbps - doporučeno (nejlepší poměr kvalita/velikost) ⭐
- 128 kbps - nejmenší soubor

### Limity (aerohosting.cz)

| Parametr | Limit | Popis |
|----------|-------|-------|
| Max execution time | 300s |Timeout pro skript |
| Post max size | 500 MB | Max velikost POST request |
| Memory limit | 256 MB | Paměť PHP procesu |

**Pozor:** Na sdíleném hostingu se dlouhá stahování mohou odpojit. Ideálně stahovat videa pod 500 MB.

## 📊 SQLite Databáze

Aplikace automaticky vytvoří SQLite databázi s historií stahování:

```sql
CREATE TABLE downloads (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    url TEXT NOT NULL,
    filename TEXT NOT NULL,
    content_type TEXT,              -- 'audio' nebo 'video'
    quality TEXT,                   -- '720', '192', etc.
    status TEXT DEFAULT 'pending',  -- 'downloading', 'completed', 'error'
    created_at DATETIME,
    completed_at DATETIME
);
```

Databáze se uklád v `data/history.db` (automaticky vytvořena).

## 🔒 Bezpečnost

- ✅ Všechny vstupy jsou validovány a escapovány
- ✅ Adresáře `data` a `temp` jsou chráněny přístupem přes web (.htaccess)
- ✅ Žádné uživatelské přihlášení (není potřeba)
- ✅ Seznamy s kvalitou jsou hardcoded (bez injekce)

**Doporučení:**
- Měňte `downloads/` adresář na soukromý přístup po nějaké lhůtě (např. 24 hodin)
- Kontrolujte diskový prostor - starší soubory odstraňujte
- Nestahujte velmi velké soubory (>1 GB)

## 🐛 Řešení problémů

### "yt-dlp není dostupný"
**Řešení:** Kontaktujte support aerohosting.cz s požadavkem na instalaci `yt-dlp`

### "Chyba při stahování: ERROR"
**Možné příčiny:**
- URL není dostupná nebo je chráněná
- Obsah byl vymazán
- yt-dlp verzi je zastaralá

**Řešení:** Zkuste jinou URL nebo se poraďte se supportem

### Stahování se zasekne
**Řešení:** Pokud server odpojí po 300 sekundách, zkuste:
1. Nižší kvalitu (360p místo 1080p)
2. Menší videa (pod 500 MB)
3. Kontaktujte support aerohosting.cz

### Databáze je "locked"
**Řešení:** Smaž soubor `data/history.db` přes FTP - vytvoří se automaticky

## 📝 Příklad použítí

```
URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
Kvalita: 720p (HD)
↓
video.mp4 (100-300 MB)
↓
Automatické stažení
```

```
URL: https://open.spotify.com/track/...
Kvalita: 192 kbps
↓
song.mp3 (5-10 MB)
↓
Automatické stažení
```

## 🔄 Aktualizace

Aby nedošlo k problémům, **neupravujte** tyto soubory na serveru:
- `index.php` - UI a frontend logika
- `download.php` - backend pro stahování
- `status.php` - polling statusu

Pokud chcete aktualizovat, vždy:
1. Stáhněte nové soubory z GitHubu
2. Vyzkoušejte lokálně
3. Nahrajte na server

## 📞 Podpora

Pro problémy s yt-dlp: kontaktujte **aerohosting.cz support**
Pro problémy s aplikací: zkontrolujte `data/history.db` a chybové logy serveru

## 📄 Licence

MIT License - použijte volně pro svůj projekt

---

**Verze:** 1.0  
**Poslední aktualizace:** 2026-04-14  
**PHP verze:** 8.2+  
**yt-dlp:** Any version
