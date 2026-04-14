# Deployment na aerohosting.cz

Krok za krokem návod pro nasazení aplikace na aerohosting.cz.

## 📋 Prerekvizity

- ✅ Účet na aerohosting.cz
- ✅ Vlastní doména
- ✅ FTP/SFTP klient (např. FileZilla)
- ✅ SSH přístup (volitelný, pro setup.sh)

## 🚀 Nasazení - Krok 1: Příprava subdomény

### V panelu aerohosting.cz:

1. **Vytvoř subdoménu**
   - Jdi do: Domény → Moje domény
   - Klikni na vaši doménu
   - Přidej subdoménu (např. `download`)
   - Odčekej propagaci (pár minut)

2. **Ověř konfiguraci**
   - Kontrola PHP verze: `https://download.vasdomena.cz/info.php`
   - (Dočasně si vytvoř `info.php` s `<?php phpinfo(); ?>`)

## 🚀 Nasazení - Krok 2: Upload souborů

### Via FTP/SFTP (FileZilla):

1. **Připoj se k serveru**
   ```
   Host: aerohosting.cz (nebo IP)
   Port: 21 (FTP) nebo 22 (SFTP)
   Uživatel: tvůj login
   Heslo: tvoje heslo
   ```

2. **Naviguj do subdomény**
   ```
   /subdomains/download/  (nebo kde je tvoje subdoména)
   ```

3. **Upload souborů**
   ```
   index.php
   download.php
   status.php
   .htaccess
   .gitignore
   setup.sh
   README.md
   DEPLOYMENT.md
   ```

4. **Vytvoř adresáře (přes FTP)**
   - Klikni pravým tlačítkem → Create directory
   - `downloads` (chmod 755)
   - `temp` (chmod 755)
   - `data` (chmod 755)

## 🚀 Nasazení - Krok 3: Inicializace (Možnost A - SSH)

Pokud máš SSH přístup (doporučeno):

```bash
# Připoj se SSH
ssh tvůj_login@aerohosting.cz

# Jdi do adresáře
cd subdomains/download

# Spusť setup skript
bash setup.sh
```

**Očekávaný výstup:**
```
✓ Adresáře vytvořeny
✓ PHP verze je OK
✓ SQLite3 je dostupné
✓ yt-dlp je dostupné
✓ Databáze je připravena
✓ INSTALACE ÚSPĚŠNÁ!
```

## 🚀 Nasazení - Krok 3: Inicializace (Možnost B - Bez SSH)

Pokud nemáš SSH, spusť manuálně přes prohlížeč:

1. **Vytvoř dočasný init soubor** (`init.php`)
```php
<?php
// Přímo v prohlížeči pro inicializaci
define('DB_FILE', __DIR__ . '/data/history.db');

if (!file_exists(dirname(DB_FILE))) {
    mkdir(dirname(DB_FILE), 0755, true);
}

try {
    $db = new SQLite3(DB_FILE);
    $db->exec('CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        filename TEXT NOT NULL,
        content_type TEXT,
        quality TEXT,
        status TEXT DEFAULT "pending",
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        completed_at DATETIME
    )');
    echo "✓ Databáze iniciáziována";
} catch (Exception $e) {
    echo "Databáze již existuje nebo chyba: " . $e->getMessage();
}
?>
```

2. **Upload `init.php` na server**

3. **V prohlížeči otevři:**
   ```
   https://download.vasdomena.cz/init.php
   ```

4. **Smaž `init.php`** - soubor už není potřeba

## ✅ Ověření instalace

1. **Otevři v prohlížeči:**
   ```
   https://download.vasdomena.cz/
   ```

2. **Měl by se zobrazit formulář** s polem pro URL

3. **Pokud se zobrazí chyba:**
   - "yt-dlp není dostupný" → Kontaktuj support aerohosting.cz
   - "Permission denied" → Zkontroluj chmod na adresářích (755)
   - Prázdná stránka → Zkontroluj error logy aerohosting.cz

## 🔧 Nastavení permisí (Přes FTP)

1. **V FileZille:**
   - Klikni pravým tlačítkem na `downloads/` → File Permissions
   - Nastav na `755` (rwxr-xr-x)
   - Stejně pro `temp/` a `data/`

2. **Nebo přes příkazovou řádku (SSH):**
   ```bash
   chmod 755 downloads temp data
   ```

## 🧪 Test stahování

1. **Zkus stáhnout video z YouTube:**
   ```
   URL: https://www.youtube.com/watch?v=dQw4w9WgXcQ
   Kvalita: 720p
   Klikni: Stáhnout
   ```

2. **Pokud uspěje:**
   - ✅ Aplikace funguje správně
   - Soubor se stáhne do `downloads/`

3. **Pokud selže:**
   - Zkontroluj error log v panelu aerohosting.cz
   - Ověř, že yt-dlp je nainstalován
   - Zkus nižší kvalitu

## 📊 Správa diskového prostoru

Na aerohosting.cz mám omezeně místa. Pravidelně:

1. **Kontroluj velikost downloads/:**
   - V panelu aerohosting.cz → Správce souborů
   - Nebo přes SSH: `du -sh downloads/`

2. **Mažu staré soubory:**
   - V FTP: Vyber soubor → Delete
   - Nebo přes SSH:
     ```bash
     # Smaž soubory starší než 7 dní
     find downloads/ -type f -mtime +7 -delete
     ```

3. **Aktualizuj README.md** s údaji o prostoru

## 🔒 Bezpečnost

- ✅ `.htaccess` blokuje přímý přístup k `data/` a `temp/`
- ✅ Všechny vstupy jsou validovány
- ✅ Žádné "admin panely" nebo přihlášení

**Doporučení:**
- Pravidelně kontroluj diskový prostor
- Mažeš staré soubory (např. starší než 7 dní)
- Updatuj aerohosting.cz PHP verzi

## 🆘 Řešení problémů

### Chyba: "yt-dlp není dostupný"

**Příčina:** yt-dlp není instalován na serveru aerohosting.cz

**Řešení:**
1. Kontaktuj support aerohosting.cz
2. Řekni: "Prosím instalujte yt-dlp (youtube-dl fork)"
3. Nebo si ho sám zkompiluj (pokud mám SSH přístup)

### Chyba: "Permission denied"

**Příčina:** Špatné práva na adresářích

**Řešení:**
```bash
chmod 755 downloads temp data
```

### Chyba: "Database is locked"

**Příčina:** SQLite3 konflikt

**Řešení:**
- Smaž `data/history.db` (vytvoří se automaticky)
- Nebo běž: `rm data/history.db`

### Stahování "timeout"

**Příčina:** Příliš velké video nebo pomalé připojení

**Řešení:**
- Zvol nižší kvalitu (360p místo 1080p)
- Nebo stahuj kratší videa
- Kontaktuj support aerohosting.cz o zvýšení max_execution_time

## 📞 Podpora

**Pro problémy s aerohosting.cz:**
- https://www.aerohosting.cz/podpora/
- Email: support@aerohosting.cz

**Pro problémy s aplikací:**
- Zkontroluj README.md - řešení problémů
- Zkontroluj error logy v panelu aerohosting.cz

## ✨ Finální kontrola

- ✅ Subdoména funguje (`https://download.vasdomena.cz/`)
- ✅ PHP 8.2 je dostupné
- ✅ SQLite3 je dostupné
- ✅ yt-dlp je dostupné
- ✅ Adresáře jsou vytvořeny (755)
- ✅ Databáze je inicializovaná
- ✅ Formulář se zobrazuje správně
- ✅ Testovací stahování funguje

**Hotovo! Aplikace je Ready to use.**

---

**Poslední aktualizace:** 2026-04-14
