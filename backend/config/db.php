<?php
require_once __DIR__ . "/config.php"; // Load .env variables

class Database {
    private static $host;
    private static $db_name;
    private static $username;
    private static $password;
    private static $conn;

    public static function init() {
        self::$host = getenv('DB_HOST');
        self::$db_name = getenv('DB_NAME');
        self::$username = getenv('DB_USER');
        self::$password = getenv('DB_PASS');
    }

    public static function getConnection() {
        if (self::$conn === null) {
            self::init(); // Ensure env variables are loaded
            try {
                self::$conn = new PDO("mysql:host=" . self::$host . ";dbname=" . self::$db_name, self::$username, self::$password);
                self::$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            } catch (PDOException $exception) {
                die("Connection error: " . $exception->getMessage());
            }
        }
        return self::$conn;
    }
}
?>
