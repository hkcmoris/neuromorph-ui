<?php
require_once '../config/db.php'; // Adjust the path as needed
require_once '../classes/JWT.php'; // Include the JWT helper class

header('Content-Type: application/json');

$data = json_decode(file_get_contents("php://input"));

if (isset($data->username) && isset($data->password)) {
    // Connect to the database and check user credentials
    $db = new Database();
    $connection = $db->connect();

    $stmt = $connection->prepare("SELECT id FROM users WHERE username = ? AND password = ?");
    $stmt->execute([$data->username, md5($data->password)]); // Example: using md5 (not recommended for production)

    if ($stmt->rowCount() > 0) {
        $user = $stmt->fetch();
        $token = JWTHelper::createToken($user['id']);
        echo json_encode(['token' => $token]);
    } else {
        http_response_code(401);
        echo json_encode(['message' => 'Invalid credentials']);
    }
} else {
    http_response_code(400);
    echo json_encode(['message' => 'Missing username or password']);
}
