<?php
/**
 * download.php - Backend pro zpracování stahování
 * Přijímá URL a kvalitu, validuje a spouští yt-dlp
 */

header('Content-Type: application/json; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 0);

define('APP_ROOT', __DIR__);
define('DOWNLOADS_DIR', APP_ROOT . '/downloads');
define('TEMP_DIR', APP_ROOT . '/temp');
define('DB_FILE', APP_ROOT . '/data/history.db');

// Základní odpověď
$response = [
    'success' => false,
    'message' => '',
    'download_id' => null,
    'filename' => null
];

// Ověření metody
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    $response['message'] = 'Pouze POST je podporován';
    http_response_code(405);
    echo json_encode($response);
    exit;
}

// Validace vstupu
$url = trim($_POST['url'] ?? '');
$quality = trim($_POST['quality'] ?? 'auto');

if (empty($url)) {
    $response['message'] = 'URL je povinná';
    echo json_encode($response);
    exit;
}

// Validace, že je to URL
if (!filter_var($url, FILTER_VALIDATE_URL)) {
    $response['message'] = 'Neplatná URL adresa';
    echo json_encode($response);
    exit;
}

// Ověření, že yt-dlp je dostupný
exec('which yt-dlp 2>/dev/null', $output, $return);
if ($return !== 0) {
    $response['message'] = 'yt-dlp není dostupný na serveru';
    http_response_code(503);
    echo json_encode($response);
    exit;
}

/**
 * Detekce typu obsahu
 */
function detectContentType($url) {
    $videoPatterns = [
        'youtube.com|youtu.be',
        'facebook.com|fb.watch',
        'tiktok.com|vm.tiktok',
        'vimeo.com',
        'bluesky.app|bsky.app',
        'twitch.tv',
        'instagram.com',
        'reddit.com',
        'dailymotion.com',
        'rumble.com',
        'odysee.com'
    ];

    $audioPatterns = [
        'spotify.com',
        'soundcloud.com',
        'rozhlas.cz|ceske-rozhlasy',
        'podcast',
        'radiozurnal.cz',
        'bandcamp.com',
        'deezer.com'
    ];

    $videoRegex = '/' . implode('|', $videoPatterns) . '/i';
    $audioRegex = '/' . implode('|', $audioPatterns) . '/i';

    if (preg_match($videoRegex, $url)) {
        return 'video';
    } elseif (preg_match($audioRegex, $url)) {
        return 'audio';
    }

    return 'video';
}

/**
 * Vytvoření yt-dlp příkazu podle typu a kvality
 */
function buildYtDlpCommand($url, $content_type, $quality, $output_file) {
    $cmd = 'yt-dlp';
    $cmd .= ' --no-warnings';
    $cmd .= ' --quiet';
    $cmd .= ' --no-progress';

    if ($content_type === 'audio') {
        // Stahování jako audio
        $cmd .= ' -x'; // Extract audio
        $cmd .= ' --audio-format mp3';

        // Kvalita zvuku
        switch ($quality) {
            case '320':
                $cmd .= ' --audio-quality 320K';
                break;
            case '192':
                $cmd .= ' --audio-quality 192K';
                break;
            case '128':
                $cmd .= ' --audio-quality 128K';
                break;
            default:
                $cmd .= ' --audio-quality 192K';
        }
    } else {
        // Stahování jako video
        // Vybrat formát podle kvality
        $format_spec = '';
        switch ($quality) {
            case '1080':
                $format_spec = 'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
                break;
            case '720':
                $format_spec = 'bestvideo[height<=720]+bestaudio/best[height<=720]';
                break;
            case '480':
                $format_spec = 'bestvideo[height<=480]+bestaudio/best[height<=480]';
                break;
            case '360':
                $format_spec = 'bestvideo[height<=360]+bestaudio/best[height<=360]';
                break;
            default:
                $format_spec = 'best[ext=mp4]/best';
        }

        $cmd .= ' -f "' . $format_spec . '"';
        $cmd .= ' --merge-output-format mp4';
    }

    // Výstupní soubor
    $cmd .= ' -o "' . escapeshellarg($output_file) . '"';

    // URL (poslední argument)
    $cmd .= ' ' . escapeshellarg($url);

    return $cmd;
}

/**
 * Zápis do SQLite databáze
 */
function saveDownloadRecord($url, $filename, $content_type, $quality) {
    try {
        $db = new SQLite3(DB_FILE);
        $db->busyTimeout(5000);

        $stmt = $db->prepare('INSERT INTO downloads (url, filename, content_type, quality, status) VALUES (:url, :filename, :content_type, :quality, :status)');
        $stmt->bindValue(':url', $url, SQLITE3_TEXT);
        $stmt->bindValue(':filename', $filename, SQLITE3_TEXT);
        $stmt->bindValue(':content_type', $content_type, SQLITE3_TEXT);
        $stmt->bindValue(':quality', $quality, SQLITE3_TEXT);
        $stmt->bindValue(':status', 'downloading', SQLITE3_TEXT);

        $result = $stmt->execute();
        $stmt->close();
        $db->close();

        return true;
    } catch (Exception $e) {
        error_log('DB Error: ' . $e->getMessage());
        return false;
    }
}

// Hlavní zpracování
try {
    $content_type = detectContentType($url);
    $extension = ($content_type === 'audio') ? 'mp3' : 'mp4';

    // Generování bezpečného jména souboru
    // Z URL vezmeme základní název nebo použijeme timestamp
    $parsed_url = parse_url($url);
    $base_name = preg_replace('/[^a-z0-9\-_]/i', '_', basename($parsed_url['path'] ?? 'download'));
    $base_name = substr($base_name, 0, 50); // Omezit délku

    if (empty($base_name)) {
        $base_name = 'download_' . time();
    }

    $filename = $base_name . '_' . date('Ymd_His') . '.' . $extension;
    $output_file = DOWNLOADS_DIR . '/' . $filename;

    // Vytvoření directory, pokud neexistuje
    if (!is_dir(DOWNLOADS_DIR)) {
        mkdir(DOWNLOADS_DIR, 0755, true);
    }

    // Uložit record do databáze
    saveDownloadRecord($url, $filename, $content_type, $quality);

    // Spuštění yt-dlp v pozadí (na shared hostingu to obvykle nejde)
    // Místo toho spustíme synchronně a vracíme výsledek
    $cmd = buildYtDlpCommand($url, $content_type, $quality, $output_file);

    // Spuštění příkazu s timeout
    $output = [];
    $return_code = 0;
    $stderr = '';

    // Zachycení stderr
    exec($cmd . ' 2>&1', $output, $return_code);
    $stderr = implode("\n", $output);

    if ($return_code === 0 && file_exists($output_file)) {
        // Úspěch - soubor existuje
        $response['success'] = true;
        $response['message'] = 'Stahování completed! Soubor je připraven ke stažení.';
        $response['filename'] = $filename;
        $response['download_id'] = basename($output_file);

        // Aktualizovat status v DB
        try {
            $db = new SQLite3(DB_FILE);
            $db->exec('UPDATE downloads SET status = "completed", completed_at = CURRENT_TIMESTAMP WHERE filename = "' . $db->escapeString($filename) . '"');
            $db->close();
        } catch (Exception $e) {
            error_log('DB Update Error: ' . $e->getMessage());
        }

    } else {
        // Chyba při stahování
        $error_msg = $stderr;

        // Pokus najít chybu v stderr
        if (strpos($stderr, 'ERROR') !== false) {
            // Extrahuj error message
            if (preg_match('/ERROR:\s*(.+?)(?:\n|$)/', $stderr, $matches)) {
                $error_msg = trim($matches[1]);
            }
        }

        $response['message'] = 'Chyba při stahování: ' . substr($error_msg, 0, 200);

        // Aktualizovat status v DB
        try {
            $db = new SQLite3(DB_FILE);
            $db->exec('UPDATE downloads SET status = "error" WHERE filename = "' . $db->escapeString($filename) . '"');
            $db->close();
        } catch (Exception $e) {
            error_log('DB Update Error: ' . $e->getMessage());
        }

        // Smazat soubor, pokud částečně existuje
        if (file_exists($output_file)) {
            @unlink($output_file);
        }
    }

} catch (Exception $e) {
    $response['message'] = 'Chyba serveru: ' . $e->getMessage();
    error_log('Exception in download.php: ' . $e->getMessage());
}

echo json_encode($response);
exit;
