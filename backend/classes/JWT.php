<?php
require_once __DIR__ . '/../vendor/autoload.php';

use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Firebase\JWT\ExpiredException;
use Dotenv\Dotenv;

// Load .env variables
$dotenv = Dotenv::createImmutable(__DIR__ . '/../');
$dotenv->load();

class JWTHelper {
    private static $secretKey;
    private static $issuer;

    public static function init() {
        self::$secretKey = $_ENV['JWT_SECRET'] ?? 'default_secret';
        self::$issuer = $_ENV['JWT_ISSUER'] ?? 'http://localhost';
    }
    
    public static function createToken($userId, $userName) {
        self::init();
        $issuedAt = time();
        $expirationTime = $issuedAt + 300; // jwt valid for 5 minutes

        $payload = [
            'iat' => $issuedAt,
            'iss' => self::$issuer,
            'exp' => $expirationTime,
            'data' => [
                'id' => $userId,
                'username' => $userName
            ]
        ];

        return JWT::encode($payload, self::$secretKey, 'HS256');
    }

    public static function validateToken($token) {
        self::init();
        try {
            $headers = new stdClass();
            $decoded = JWT::decode($token, new Key(self::$secretKey, 'HS256'), $headers);
            return (array) $decoded->data; // Return user data
        } catch (ExpiredException $e) {
            return null; // Token expired
        } catch (Exception $e) {
            return null; // Invalid token
        }
    }
}
