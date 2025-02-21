<?php
require_once 'vendor/autoload.php'; // Make sure this path is correct

use Firebase\JWT\JWT;
use Firebase\JWT\ExpiredException;

class JWTHelper {
    private static $secretKey = 'your_secret_key'; // Change this to a secure key
    private static $issuer = 'http://devground.cz'; // Your domain

    public static function createToken($userId) {
        $issuedAt = time();
        $expirationTime = $issuedAt + 3600; // jwt valid for 1 hour

        $payload = [
            'iat' => $issuedAt,
            'iss' => self::$issuer,
            'exp' => $expirationTime,
            'data' => [
                'userId' => $userId
            ]
        ];

        return JWT::encode($payload, self::$secretKey);
    }

    public static function validateToken($token) {
        try {
            $decoded = JWT::decode($token, self::$secretKey, ['HS256']);
            return (array) $decoded->data; // Return user data
        } catch (ExpiredException $e) {
            return null; // Token expired
        } catch (Exception $e) {
            return null; // Invalid token
        }
    }
}
