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

// Function to fetch photos based on entry_id
function getPhotosByEntryId($entry_id) {
    global $your_db_connection;

    $query = "SELECT username, session_id, picture_address, datetime FROM pictures WHERE entry_id = $entry_id ORDER BY username, session_id";
    $result = mysqli_query($your_db_connection, $query);

    $photos = array();

    while ($row = mysqli_fetch_assoc($result)) {
        $username = $row['username'];
        $session_id = $row['session_id'];
        $picture_address = $row['picture_address'];
        $datetime = $row['datetime'];

        // Add the flattened photo details to the list
        $photos[] = array(
            'username' => $username,
            'session_id' => $session_id,
            'picture_address' => $picture_address,
            'datetime' => $datetime
        );
    }

    return $photos;
}

// Handle the GET request
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // Assuming you have sanitized and validated the input
    $entry_id = $_GET['entry_id'];

    // Fetch photos based on entry_id
    $photos = getPhotosByEntryId($entry_id);

    // Return JSON response
    header('Content-Type: application/json');
    echo json_encode($photos);
} else {
    // Handle other HTTP methods or provide an error message
    http_response_code(405); // Method Not Allowed
    echo "Only GET requests are allowed.";
}

// Close the database connection
mysqli_close($your_db_connection);
?>