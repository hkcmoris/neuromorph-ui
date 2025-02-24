<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../classes/User.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['username'], $data['email'], $data['password']) || 
    empty(trim($data['username'])) || 
    empty(trim($data['email'])) || 
    empty(trim($data['password']))) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$user = new User();
$response = $user->register($data['username'], $data['email'], $data['password']);

if (isset($response['error'])) {
    http_response_code(400);
}

echo json_encode($response);
?>
