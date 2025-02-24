<?php
require_once __DIR__ . '/../config/db.php';
require_once __DIR__ . '/../classes/User.php';

header('Content-Type: application/json');

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['email'], $data['password']) || 
    empty(trim($data['email'])) || 
    empty(trim($data['password']))) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing email or password']);
    exit;
}

$user = new User();
$response = $user->login($data['email'], $data['password']);

if (isset($response['error'])) {
    http_response_code(401);
}

echo json_encode($response);
?>
