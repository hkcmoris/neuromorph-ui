<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . '/../config/db.php'; // Adjust path if needed
require_once __DIR__ . '/../classes/JWT.php'; // Ensure JWT class is properly included

header('Content-Type: application/json');

// Get headers safely
$headers = function_exists('apache_request_headers') ? apache_request_headers() : getallheaders();


$filePath = __DIR__ . '/logs/api.log';
$result = file_put_contents($filePath, json_encode($headers, JSON_PRETTY_PRINT) . "\n", FILE_APPEND);
if ($result === false) {
    echo json_encode(["message" => "Failed to write to log file."]);
}

if (!isset($headers['Authorization'])) {
    http_response_code(401); // or 400 if you prefer
    echo json_encode(['message' => 'Authorization header missing']);
    exit;
}

// Extract and validate token
$token = str_replace('Bearer ', '', $headers['Authorization']);
$userData = JWTHelper::validateToken($token);

if (!$userData) {
    http_response_code(401);
    echo json_encode(['message' => 'Unauthorized']);
    exit;
}

// Successfully authenticated response
echo json_encode(['message' => 'Protected endpoint!', 'id' => $userData['id']]);
?>