<?php
// Database connection details
$database_host = 'localhost';
$database_user = 'xxxx';
$database_password = 'xxxx';
$database_name = 'flutter_app';

// Establish the database connection
$your_db_connection = mysqli_connect($database_host, $database_user, $database_password, $database_name);

// Check the connection
if (!$your_db_connection) {
    die("Connection failed: " . mysqli_connect_error());
}

// Function to generate a 12-bit randomized string
function generateRandomString() {
    $characters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    $randomString = '';
    $length = 12;

    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[rand(0, strlen($characters) - 1)];
    }

    return $randomString;
}

// Function to get the latest session_id for a given entry_id and username
function getLatestSessionId($entry_id, $username) {
    global $your_db_connection;
    $query = "SELECT MAX(session_id) AS max_session_id, MAX(datetime) AS latest_datetime FROM pictures WHERE entry_id = $entry_id AND username = '$username'";
    $result = mysqli_query($your_db_connection, $query);
    $row = mysqli_fetch_assoc($result);

    // Check if the latest photo was uploaded less than 1 minute ago
    $latestDatetime = strtotime($row['latest_datetime']);
    if (time() - $latestDatetime < 60) {
        return $row['max_session_id']; // Reuse the same session_id
    } else {
        return $row['max_session_id'] + 1; // Generate a new session_id
    }
}

// Handle the HTTPS POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Assuming you have sanitized and validated the input
    $entry_id = $_POST['entry_id'];
    $username = $_POST['username'];

    // Get the session_id
    $session_id = getLatestSessionId($entry_id, $username);

    // Directory to save the pictures
    $uploadDirectory = '/var/www/html/flutter/pics/';

    // Process each photo in the POST request
    foreach ($_FILES['photos']['error'] as $key => $error) {
        if ($error == UPLOAD_ERR_OK) {
            $tmp_name = $_FILES['photos']['tmp_name'][$key];
            $extension = pathinfo($_FILES['photos']['name'][$key], PATHINFO_EXTENSION);

            // Generate a 12-bit randomized string for picture_address
            $picture_address = generateRandomString();

            // Save the photo to the directory
            $newFileName = $uploadDirectory . $picture_address . '.' . $extension;
            move_uploaded_file($tmp_name, $newFileName);

            // Insert the record into the pictures table
            $query = "INSERT INTO pictures (picture_address, entry_id, username, datetime, session_id) VALUES ('$picture_address', $entry_id, '$username', NOW(), $session_id)";
            mysqli_query($your_db_connection, $query);
        }
    }

    // Return results if needed
    echo "Photos uploaded successfully!";
} else {
    // Handle other HTTP methods or provide an error message
    http_response_code(405); // Method Not Allowed
    echo "Only POST requests are allowed.";
}

// Close the database connection
mysqli_close($your_db_connection);
?>