<?php
/**
 * status.php - Polling pro stav stahování
 * Vrací JSON s aktuálním stavem
 */

header('Content-Type: application/json; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 0);

define('APP_ROOT', __DIR__);
define('DOWNLOADS_DIR', APP_ROOT . '/downloads');
define('DB_FILE', APP_ROOT . '/data/history.db');

$response = [
    'status' => 'unknown',
    'filename' => null,
    'message' => '',
    'filesize' => null,
    'exists' => false
];

$download_id = $_GET['id'] ?? '';

if (empty($download_id)) {
    $response['message'] = 'Chybí ID stahování';
    http_response_code(400);
    echo json_encode($response);
    exit;
}

try {
    $db = new SQLite3(DB_FILE);
    $db->busyTimeout(5000);

    // Normalizace jména souboru
    // ID je buď jen 'filename' nebo 'downloads/filename'
    $filename = basename($download_id);

    // Hledání v databázi
    $result = $db->querySingle(
        'SELECT status, filename FROM downloads WHERE filename = "' . $db->escapeString($filename) . '" LIMIT 1',
        true
    );

    $db->close();

    if ($result) {
        $response['filename'] = $result['filename'];
        $response['status'] = $result['status'];

        // Pokud je completed, vrátit info o souboru
        if ($result['status'] === 'completed') {
            $file_path = DOWNLOADS_DIR . '/' . $result['filename'];
            if (file_exists($file_path)) {
                $response['exists'] = true;
                $response['filesize'] = filesize($file_path);
                $response['message'] = 'Hotovo';
            } else {
                $response['status'] = 'error';
                $response['message'] = 'Soubor nebyl nalezen';
            }
        } else if ($result['status'] === 'downloading') {
            $response['message'] = 'Stahování v běhu...';
        } else if ($result['status'] === 'error') {
            $response['message'] = 'Chyba při stahování';
        }
    } else {
        // Pokud není v DB, zkontroluj, zda soubor existuje přímo
        $file_path = DOWNLOADS_DIR . '/' . $filename;
        if (file_exists($file_path)) {
            $response['status'] = 'completed';
            $response['filename'] = $filename;
            $response['exists'] = true;
            $response['filesize'] = filesize($file_path);
            $response['message'] = 'Hotovo';
        } else {
            $response['status'] = 'not_found';
            $response['message'] = 'Stahování nenalezeno';
        }
    }

} catch (Exception $e) {
    $response['status'] = 'error';
    $response['message'] = 'Chyba při kontrole statusu: ' . $e->getMessage();
    error_log('Exception in status.php: ' . $e->getMessage());
}

echo json_encode($response);
exit;
