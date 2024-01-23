<?php

// Replace these with your actual database credentials
$servername = "localhost";
$username = "xxxx";
$password = "xxxx";
$dbname = "flutter_app";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if 'entryid' key is present in the POST method
if (isset($_POST['entryid'])) {
    // Retrieve details for a specific entry along with the author's details
    $entryid = $_POST['entryid'];
    
    $sql = "
        SELECT e.entry_id, e.`long`, e.lat, e.time, e.date, e.content,
               u.username AS author_username, u.user_id AS author_user_id
        FROM entries e
        INNER JOIN users u ON e.user_id = u.user_id
        WHERE e.entry_id = '$entryid';
    ";

    $result = $conn->query($sql);

    if ($result) {
        $entryData = $result->fetch_assoc();

        // Convert the data to JSON format
        $jsonResponse = json_encode($entryData, JSON_PRETTY_PRINT);

        // Output the JSON response
        echo $jsonResponse;
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }
} else {
    // Retrieve details for all available entries
    $sql = "
        SELECT e.entry_id, e.`long`, e.lat, e.time, e.date, e.content,
               u.username AS author_username, u.user_id AS author_user_id
        FROM entries e
        INNER JOIN users u ON e.user_id = u.user_id;
    ";

    $result = $conn->query($sql);

    if ($result) {
        $entriesData = array();

        while ($row = $result->fetch_assoc()) {
            $entriesData[] = $row;
        }

        // Convert the data to JSON format
        $jsonResponse = json_encode($entriesData, JSON_PRETTY_PRINT);

        // Output the JSON response
        echo $jsonResponse;
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }
}

// Close the database connection
$conn->close();

?>