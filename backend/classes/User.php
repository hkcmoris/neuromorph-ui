<?php
require_once __DIR__ . '/../config/db.php';

class User {
    private $conn;

    public function __construct() {
        $this->conn = Database::getConnection();
    }

    // Check if username or email already exists
    public function userExists($username, $email) {
        $sql = "SELECT id FROM users WHERE username = ? OR email = ?";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([$username, $email]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Register new user
    public function register($username, $email, $password) {
        if ($this->userExists($username, $email)) {
            return ['error' => 'Username or email already taken'];
        }

        $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
        $sql = "INSERT INTO users (username, email, password) VALUES (?, ?, ?)";
        $stmt = $this->conn->prepare($sql);
        if ($stmt->execute([$username, $email, $hashedPassword])) {
            return ['success' => 'User registered successfully'];
        }
        return ['error' => 'Registration failed'];
    }

    // Login user
    public function login($email, $password) {
        $sql = "SELECT id, username, password FROM users WHERE email = ?";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($password, $user['password'])) {
            require_once __DIR__ . '/../classes/JWT.php';
            return [
                'token' => JWTHelper::createToken($user['id'], $user['username'])
            ];
        }
        return ['error' => 'Invalid credentials'];
    }
}
?>
