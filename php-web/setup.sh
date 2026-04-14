#!/bin/bash
# ================================================================
# Setup skript pro yt-dlp Stahovač PHP aplikaci
# Spusť: bash setup.sh
# ================================================================

set -e  # Exit on error

echo "=========================================================="
echo " yt-dlp Stahovač - PHP Setup"
echo "=========================================================="
echo

# Barvy pro výstup
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Detekce aktuálního adresáře
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$INSTALL_DIR"

echo -e "${YELLOW}ℹ️  Instalační adresář:${NC} $INSTALL_DIR"
echo

# ================================================================
# 1. Vytvoření adresářů
# ================================================================

echo -e "${YELLOW}📁 Vytváření adresářů...${NC}"

mkdir -p downloads temp data

# Nastavení oprávnění (755 = rwxr-xr-x)
chmod 755 downloads temp data

echo -e "${GREEN}✓ Adresáře vytvořeny${NC}"
echo "  - downloads/ (stažené soubory)"
echo "  - temp/ (dočasné soubory)"
echo "  - data/ (SQLite databáze)"
echo

# ================================================================
# 2. Ověření PHP verze
# ================================================================

echo -e "${YELLOW}🔍 Kontrola PHP verze...${NC}"

PHP_VERSION=$(php -r 'echo PHP_VERSION;' 2>/dev/null || echo "0")
echo "  PHP verze: $PHP_VERSION"

if [[ "$PHP_VERSION" == 0 ]]; then
    echo -e "${RED}❌ PHP není dostupné. Instalace selhala.${NC}"
    exit 1
fi

# Kontrola PHP 8.2+
if [[ $(php -r 'echo (PHP_VERSION_ID >= 80200) ? "1" : "0";') == "0" ]]; then
    echo -e "${YELLOW}⚠️  Upozornění: Doporučuje se PHP 8.2 nebo novější${NC}"
else
    echo -e "${GREEN}✓ PHP verze je OK${NC}"
fi
echo

# ================================================================
# 3. Ověření SQLite3
# ================================================================

echo -e "${YELLOW}🔍 Kontrola SQLite3 rozšíření...${NC}"

if php -r 'extension_loaded("sqlite3") or die("0");' 2>/dev/null; then
    echo -e "${GREEN}✓ SQLite3 je dostupné${NC}"
else
    echo -e "${RED}❌ SQLite3 rozšíření není dostupné.${NC}"
    echo "    Kontaktuj support aerohosting.cz k aktivaci SQLite3"
    exit 1
fi
echo

# ================================================================
# 4. Ověření yt-dlp
# ================================================================

echo -e "${YELLOW}🔍 Kontrola yt-dlp...${NC}"

if command -v yt-dlp &> /dev/null; then
    YT_DLP_VERSION=$(yt-dlp --version 2>/dev/null | head -1 || echo "unknown")
    echo -e "${GREEN}✓ yt-dlp je dostupné${NC}"
    echo "  Verze: $YT_DLP_VERSION"
else
    echo -e "${RED}❌ yt-dlp není dostupné!${NC}"
    echo "    Kontaktuj support aerohosting.cz s požadavkem:"
    echo "    'Prosím instalujte yt-dlp - nástroj pro stahování médií'"
    echo
    echo "    Aplikace bude fungovat po instalaci yt-dlp."
fi
echo

# ================================================================
# 5. Inicializace SQLite databáze
# ================================================================

echo -e "${YELLOW}📊 Inicializace SQLite databáze...${NC}"

php << 'INIT_DB'
<?php
define('DB_FILE', getcwd() . '/data/history.db');

try {
    $db = new SQLite3(DB_FILE);
    $db->busyTimeout(5000);

    // Kontrola, zda tabulka už existuje
    $result = $db->querySingle("SELECT name FROM sqlite_master WHERE type='table' AND name='downloads'");

    if (!$result) {
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
        echo "  ✓ Tabulka 'downloads' vytvořena\n";
    } else {
        echo "  ✓ Tabulka 'downloads' již existuje\n";
    }

    $db->close();
    echo "✓ Databáze je připravena\n";
} catch (Exception $e) {
    echo "✗ Chyba při inicializaci DB: " . $e->getMessage() . "\n";
    exit(1);
}
?>
INIT_DB

echo

# ================================================================
# 6. Kontrola souboru .htaccess
# ================================================================

echo -e "${YELLOW}🔍 Kontrola .htaccess...${NC}"

if [ -f ".htaccess" ]; then
    echo -e "${GREEN}✓ .htaccess je na místě${NC}"
else
    echo -e "${YELLOW}⚠️  .htaccess chybí - bezpečnost nemusí fungovat!${NC}"
fi
echo

# ================================================================
# 7. Test spuštění aplikace
# ================================================================

echo -e "${YELLOW}🧪 Test aplikace...${NC}"

# Kontrola index.php
if [ ! -f "index.php" ]; then
    echo -e "${RED}❌ index.php chybí!${NC}"
    exit 1
fi

# Kontrola download.php
if [ ! -f "download.php" ]; then
    echo -e "${RED}❌ download.php chybí!${NC}"
    exit 1
fi

# Kontrola status.php
if [ ! -f "status.php" ]; then
    echo -e "${RED}❌ status.php chybí!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Všechny povinné soubory jsou přítomny${NC}"
echo

# ================================================================
# 8. Shrnutí
# ================================================================

echo "=========================================================="
echo -e "${GREEN}✅ INSTALACE ÚSPĚŠNÁ!${NC}"
echo "=========================================================="
echo
echo "📍 Přístup k aplikaci:"
echo "   https://download.vasdomena.cz/"
echo "   (nahraď 'vasdomena.cz' svou doménou)"
echo
echo "📂 Struktura:"
echo "   - downloads/  → stažené soubory"
echo "   - temp/       → dočasné soubory"
echo "   - data/       → SQLite databáze"
echo
echo "📖 Dokumentace:"
echo "   Přečti: README.md"
echo
echo "🐛 Pokud se vyskytne problém:"
echo "   1. Zkontroluj README.md - řešení problémů"
echo "   2. Ověř, že yt-dlp je nainstalován"
echo "   3. Kontaktuj support aerohosting.cz"
echo
echo "=========================================================="
