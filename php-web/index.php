<?php
/**
 * yt-dlp Stahovač - PHP 8.2 Web Aplikace
 * Jednoduchá webová aplikace pro stahování audio a video obsahu
 *
 * Režim: Bez přihlašování, sdílení - jen stahování
 * Hostování: aerohosting.cz (PHP 8.2)
 */

session_start();
error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Základní konfigurace
define('APP_ROOT', __DIR__);
define('DOWNLOADS_DIR', APP_ROOT . '/downloads');
define('TEMP_DIR', APP_ROOT . '/temp');
define('DB_FILE', APP_ROOT . '/data/history.db');

// Vytvoření adresářů - bez zastavení v případě chyby
$dirs_to_create = [DOWNLOADS_DIR, TEMP_DIR, APP_ROOT . '/data'];
foreach ($dirs_to_create as $dir) {
    if (!is_dir($dir)) {
        @mkdir($dir, 0755, true); // @ potlačuje varování
    }
}

// Inicializace SQLite databáze - bezpečně
function initDatabase() {
    try {
        if (!file_exists(DB_FILE)) {
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
            $db->close();
        }
        return true;
    } catch (Exception $e) {
        error_log('DB Init Error: ' . $e->getMessage());
        return false;
    }
}

// Volaj initDatabase ale ignoruj chyby - aplikace bude fungovat i bez DB
$db_ok = initDatabase();

// Detekce typu obsahu podle domény
function detectContentType($url) {
    // Regex patterny pro video platformy
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

    // Regex patterny pro audio/podcast
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

    // Výchozí - pokusit se stáhnout jako video
    return 'video';
}

// Ověření, že yt-dlp je dostupný
function checkYtDlp() {
    $output = [];
    $return = 0;
    exec('which yt-dlp 2>/dev/null', $output, $return);
    return $return === 0;
}

?>
<!DOCTYPE html>
<html lang="cs">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>yt-dlp Stahovač</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/css/bootstrap.min.css" rel="stylesheet">
    <style>
        :root {
            --primary: #0d6efd;
            --success: #198754;
            --danger: #dc3545;
            --warning: #ffc107;
            --info: #0dcaf0;
        }

        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        }

        .container-main {
            max-width: 900px;
            margin-top: 3rem;
            margin-bottom: 3rem;
        }

        .card {
            border: none;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            border-radius: 12px;
        }

        .card-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 12px 12px 0 0 !important;
            padding: 1.5rem;
            border: none;
        }

        .card-header h1 {
            margin: 0;
            font-size: 1.8rem;
            font-weight: 600;
        }

        .form-control, .form-select {
            border-radius: 8px;
            border: 1px solid #dee2e6;
            padding: 0.75rem 1rem;
        }

        .form-control:focus, .form-select:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 0.2rem rgba(13, 110, 253, 0.15);
        }

        .btn {
            border-radius: 8px;
            padding: 0.75rem 2rem;
            font-weight: 500;
            border: none;
            transition: all 0.3s ease;
        }

        .btn-primary {
            background: var(--primary);
        }

        .btn-primary:hover {
            background: #0b5ed7;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(13, 110, 253, 0.3);
        }

        .quality-group {
            background: #f8f9fa;
            padding: 1.5rem;
            border-radius: 8px;
            margin-top: 1.5rem;
        }

        .quality-group h5 {
            margin-bottom: 1rem;
            color: #333;
        }

        .form-check {
            margin-bottom: 0.75rem;
        }

        .form-check-input {
            width: 1.2em;
            height: 1.2em;
            margin-top: 0.35em;
            cursor: pointer;
            border-radius: 4px;
        }

        .form-check-label {
            cursor: pointer;
            margin-left: 0.5rem;
        }

        .status-box {
            background: white;
            border-left: 4px solid var(--info);
            padding: 1.5rem;
            border-radius: 8px;
            margin-top: 1.5rem;
            display: none;
        }

        .status-box.show {
            display: block;
        }

        .status-box.success {
            border-left-color: var(--success);
        }

        .status-box.error {
            border-left-color: var(--danger);
        }

        .progress {
            height: 8px;
            border-radius: 10px;
            background-color: #e9ecef;
        }

        .progress-bar {
            background: linear-gradient(90deg, var(--primary), var(--info));
            border-radius: 10px;
        }

        .spinner-border {
            color: var(--primary);
        }

        .alert {
            border-radius: 8px;
            border: none;
        }

        .text-muted {
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container-main">
        <div class="card">
            <div class="card-header">
                <h1>📥 yt-dlp Stahovač</h1>
                <p class="mb-0 mt-2" style="font-size: 0.95rem; opacity: 0.95;">Jednoduché stahování audio a video obsahu</p>
            </div>

            <div class="card-body p-4">
                <?php if (!$db_ok): ?>
                    <div class="alert alert-warning" role="alert">
                        <strong>⚠️ Upozornění:</strong> Databáze se nepodařilo inicializovat. Aplikace bude fungovat, ale historia stahování se neuloží. Zkontroluj práva na serveru.
                    </div>
                <?php endif; ?>

                <?php if (!checkYtDlp()): ?>
                    <div class="alert alert-danger" role="alert">
                        <strong>⚠️ Chyba:</strong> yt-dlp není nainstalován nebo není dostupný v PATH.
                        Na serveru kontaktuj podporu pro instalaci yt-dlp.
                    </div>
                <?php endif; ?>

                <form id="downloadForm">
                    <!-- URL Input -->
                    <div class="mb-3">
                        <label for="urlInput" class="form-label">🔗 URL stránky</label>
                        <input
                            type="url"
                            class="form-control form-control-lg"
                            id="urlInput"
                            name="url"
                            placeholder="https://www.youtube.com/watch?v=..."
                            required
                        >
                        <small class="text-muted d-block mt-2">
                            Podporované: YouTube, Facebook, TikTok, Instagram, Vimeo, Spotify, SoundCloud, Rozhlas.cz a další
                        </small>
                    </div>

                    <!-- Content Type Detection -->
                    <div class="quality-group" id="qualityContainer" style="display: none;">
                        <h5>⚙️ Nastavení kvality</h5>

                        <!-- Audio Qualities -->
                        <div id="audioQualities" style="display: none;">
                            <label class="mb-2"><strong>Zvuk - Bitrate:</strong></label>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="320" id="audio320">
                                <label class="form-check-label" for="audio320">320 kbps (nejlepší kvalita)</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="192" id="audio192" checked>
                                <label class="form-check-label" for="audio192">192 kbps (doporučeno)</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="128" id="audio128">
                                <label class="form-check-label" for="audio128">128 kbps (nejmenší velikost)</label>
                            </div>
                        </div>

                        <!-- Video Qualities -->
                        <div id="videoQualities" style="display: none;">
                            <label class="mb-2"><strong>Video - Rozlišení:</strong></label>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="1080" id="video1080">
                                <label class="form-check-label" for="video1080">1080p (Full HD - největší soubor)</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="720" id="video720" checked>
                                <label class="form-check-label" for="video720">720p (HD - doporučeno)</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="480" id="video480">
                                <label class="form-check-label" for="video480">480p (menší soubor)</label>
                            </div>
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="quality" value="360" id="video360">
                                <label class="form-check-label" for="video360">360p (nejmenší soubor)</label>
                            </div>
                        </div>
                    </div>

                    <!-- Submit Button -->
                    <div class="mt-4">
                        <button type="submit" class="btn btn-primary btn-lg w-100">
                            <span class="spinner-border spinner-border-sm me-2" id="loadingSpinner" style="display: none;"></span>
                            <span id="submitText">📥 Stáhnout</span>
                        </button>
                    </div>
                </form>

                <!-- Status Messages -->
                <div id="statusBox" class="status-box">
                    <div id="statusMessage"></div>
                    <div id="progressContainer" style="display: none;" class="mt-3">
                        <small class="text-muted d-block mb-2">Stahování v běhu...</small>
                        <div class="progress">
                            <div class="progress-bar" id="progressBar" style="width: 0%"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.3.0/js/bootstrap.bundle.min.js"></script>
    <script>
        const form = document.getElementById('downloadForm');
        const urlInput = document.getElementById('urlInput');
        const qualityContainer = document.getElementById('qualityContainer');
        const audioQualities = document.getElementById('audioQualities');
        const videoQualities = document.getElementById('videoQualities');
        const statusBox = document.getElementById('statusBox');
        const statusMessage = document.getElementById('statusMessage');
        const submitBtn = form.querySelector('button[type="submit"]');
        const loadingSpinner = document.getElementById('loadingSpinner');
        const submitText = document.getElementById('submitText');

        // Detekce typu obsahu při změně URL
        urlInput.addEventListener('blur', function() {
            if (this.value) {
                // Simulace detekce typu - v produkci zavolá backend
                const url = this.value.toLowerCase();
                const isAudio = /spotify|soundcloud|rozhlas|podcast|bandcamp|deezer/.test(url);

                qualityContainer.style.display = 'block';
                if (isAudio) {
                    audioQualities.style.display = 'block';
                    videoQualities.style.display = 'none';
                } else {
                    audioQualities.style.display = 'none';
                    videoQualities.style.display = 'block';
                }
            }
        });

        // Odeslání formuláře
        form.addEventListener('submit', async function(e) {
            e.preventDefault();

            const url = urlInput.value.trim();
            const quality = document.querySelector('input[name="quality"]:checked')?.value || 'auto';

            if (!url) {
                showStatus('❌ Prosím, zadej URL stránky', 'error');
                return;
            }

            // Zakázání tlačítka a zobrazení loaderu
            submitBtn.disabled = true;
            loadingSpinner.style.display = 'inline-block';
            submitText.textContent = 'Zpracovávám...';

            try {
                const response = await fetch('download.php', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: `url=${encodeURIComponent(url)}&quality=${encodeURIComponent(quality)}`
                });

                const data = await response.json();

                if (data.success) {
                    showStatus(`✅ ${data.message}`, 'success');
                    // Resetuj formulář
                    form.reset();
                    qualityContainer.style.display = 'none';

                    // Pokud má download ID, spusť polling pro status
                    if (data.download_id) {
                        pollDownloadStatus(data.download_id);
                    }
                } else {
                    showStatus(`❌ Chyba: ${data.message}`, 'error');
                }
            } catch (error) {
                showStatus(`❌ Chyba při komunikaci se serverem: ${error.message}`, 'error');
            } finally {
                submitBtn.disabled = false;
                loadingSpinner.style.display = 'none';
                submitText.textContent = '📥 Stáhnout';
            }
        });

        // Zobrazení statusu
        function showStatus(message, type = 'info') {
            statusBox.className = `status-box show ${type}`;
            statusMessage.textContent = message;
            statusMessage.className = `status-text text-${type === 'success' ? 'success' : (type === 'error' ? 'danger' : 'muted')}`;
        }

        // Polling pro stav stahování
        function pollDownloadStatus(downloadId) {
            let pollCount = 0;
            const maxPolls = 360; // 6 minut při 1 sekundě interval

            const pollInterval = setInterval(async () => {
                try {
                    const response = await fetch(`status.php?id=${encodeURIComponent(downloadId)}`);
                    const data = await response.json();

                    if (data.status === 'completed') {
                        showStatus(`✅ Hotovo! Soubor: ${data.filename}`, 'success');
                        clearInterval(pollInterval);
                    } else if (data.status === 'error') {
                        showStatus(`❌ Chyba: ${data.message}`, 'error');
                        clearInterval(pollInterval);
                    } else if (data.status === 'downloading') {
                        showStatus(`📥 Stahování: ${data.filename}...`, 'info');
                    }

                    pollCount++;
                    if (pollCount > maxPolls) {
                        clearInterval(pollInterval);
                    }
                } catch (error) {
                    console.error('Chyba při polling statusu:', error);
                    clearInterval(pollInterval);
                }
            }, 1000);
        }
    </script>
</body>
</html>
