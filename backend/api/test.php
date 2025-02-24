<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

$filePath = __DIR__ . '/logs/api.log';
$result = file_put_contents($filePath, 'Debug message', FILE_APPEND);
if ($result === false) {
    echo json_encode(["message" => "Failed to write to log file."]);
} else {
    echo json_encode(["message" => "API is working!"]);
}

?>
