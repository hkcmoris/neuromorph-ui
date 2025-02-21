<?php
require_once '../config/db.php'; // Adjust the path as needed
require_once '../classes/JWT.php'; // Include the JWT helper class

header('Content-Type: application/json');

// Get the Authorization header
$headers = apache_request_headers();
if (isset($headers['Authorization'])) {
    $token = str_replace('Bearer ', '', $headers['Authorization']);
    $userData = JWTHelper::validateToken($token);

    if ($userData) {
        // User is authenticated
        echo json_encode(['message' => 'This is a protected endpoint!', 'userId' => $userData['userId']]);
    } else {
        http_response_code(401);
        echo json_encode(['message' => 'Unauthorized']);
    }
} else {
    http_response_code(400);
    echo json_encode(['message' => 'Authorization header missing']);
}
