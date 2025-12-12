<?php
header("Content-Type: application/json");
error_reporting(0);
$conn = mysqli_connect("localhost","root","","gd2php");

if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

$json = file_get_contents('php://input');
$data = json_decode($json, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Invalid JSON"]);
    exit();
}

$username = mysqli_real_escape_string($conn, $data['username']);
$email = isset($data['email']) ? mysqli_real_escape_string($conn, $data['email']) : null;
$password = password_hash($data['password'], PASSWORD_BCRYPT);
$type = mysqli_real_escape_string($conn, $data['type']);
$token = isset($data['token']) ? mysqli_real_escape_string($conn, $data['token']) : null;

switch ($type) {
    case 'login':
        $logStmt = $conn->prepare("SELECT * FROM `users` WHERE BINARY `user` = ?");
        $logStmt->bind_param("s", $username);
        $logStmt->execute();
        $result = $logStmt->get_result();
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            if (password_verify($data['password'], $row['pass'])) {

                $newToken = bin2hex(random_bytes(32));
                $expire = date('Y-m-d H:i:s', strtotime('+30 days'));

                $updateStmt = $conn->prepare("UPDATE `users` SET `sesh_token` = ?, `token_expire` = ? WHERE BINARY `user` = ?");
                $updateStmt->bind_param("sss", $newToken, $expire, $username);
                $updateStmt->execute();
                $updateStmt->close();

                unset($row['pass']);
                $row['token'] = $newToken;
                echo json_encode(["status" => "success", "message" => "Login successful",
            "user" => $row]);
            } else {
                http_response_code(401);
                echo json_encode(["status" => "error", "message" => "Invalid credentials"]);
            }
        } else {
            http_response_code(401);
            echo json_encode(["status" => "error", "message" => "Account does not exist"]);
        }
        $logStmt->close();
        break;
    case 'signup':
        // Validate required fields
        if (empty($data['username']) || empty($data['email']) || empty($data['password'])) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Username, email, and password are required"]);
            exit();
        }

        // Validate email format
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            http_response_code(400);
            echo json_encode(["status" => "error", "message" => "Invalid email format"]);
            exit();
        }

        // Check if user or email already exists
        $chkStmt = $conn->prepare("SELECT * FROM `users` WHERE `user` = ? OR `email` = ?");
        $chkStmt->bind_param("ss", $username, $email);
        $chkStmt->execute();
        $chkResult = $chkStmt->get_result();
        if ($chkResult->num_rows > 0) {
            http_response_code(409);
            echo json_encode(["status" => "error", "message" => "Username or email already exists"]);
            $chkStmt->close();
            exit();
        }
        $chkStmt->close();

        // Generate initial token
        $newToken = bin2hex(random_bytes(32));
        $expire = date('Y-m-d H:i:s', strtotime('+30 days'));

        // Insert new user with token
        $signStmt = $conn->prepare("INSERT INTO `users` (`user`, `email`, `pass`, `sesh_token`, `token_expire`) VALUES (?, ?, ?, ?, ?)");
        $signStmt->bind_param("sssss", $username, $email, $password, $newToken, $expire);
        if ($signStmt->execute()) {
            echo json_encode([
                "status" => "success", 
                "message" => "User registered successfully",
                "user" => [
                    "user" => $username,
                    "email" => $email,
                    "token" => $newToken
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Registration failed"]);
        }
        $signStmt->close();
        break;
    case 'delete':
        if (!tokenCheck($conn, $token)) {
            http_response_code(401);
            echo json_encode(["status" => "error", "message" => "Invalid or expired token"]);
            exit();
        }
        $deleteStmt = $conn->prepare("DELETE FROM `users` WHERE `sesh_token` = ?");
        $deleteStmt->bind_param("s", $token);
        if ($deleteStmt->execute()) {
            echo json_encode(["status" => "success", "message" => "User deleted successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Deletion failed"]);
        }
        $deleteStmt->close();
        break;
    case 'edit':
        if (!tokenCheck($conn, $token)) {
            http_response_code(401);
            echo json_encode(["status" => "error", "message" => "Invalid or expired token"]);
            exit();
        }
        $editStmt = $conn->prepare("UPDATE `users` SET `user` = ?, `email` = ? WHERE `sesh_token` = ?");
        $editStmt->bind_param("sss", $username, $email, $token);
        if ($editStmt->execute()) {
            echo json_encode(["status" => "success", "message" => "User updated successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Update failed"]);
        }
        $editStmt->close();
        break;
    case 'logout':
        $logoutStmt = $conn->prepare("UPDATE `users` SET `sesh_token` = NULL, `token_expire` = NULL WHERE BINARY `user` = ?");
        $logoutStmt->bind_param("s", $username);
        if ($logoutStmt->execute()) {
            echo json_encode(["status" => "success", "message" => "Logout successful"]);
        } else {
            http_response_code(500);
            echo json_encode(["status" => "error", "message" => "Logout failed"]);
        }
        $logoutStmt->close();
        break;
    default:
        http_response_code(400);
        echo json_encode(["status" => "error", "message" => "Invalid request type"]);
        exit();
        break;
}

function tokenCheck($conn, $token) {
    $stmt = $conn->prepare("SELECT * FROM `users` WHERE `sesh_token` = ? AND `token_expire` > NOW()");
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();
    $isValid = $result->num_rows > 0;
    $stmt->close();
    return $isValid;
}