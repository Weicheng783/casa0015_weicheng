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

// Get data from POST parameters
$long = isset($_POST['long']) ? $_POST['long'] : '';
$lat = isset($_POST['lat']) ? $_POST['lat'] : '';
$username = isset($_POST['username']) ? $_POST['username'] : ''; // Updated to accept username
$time = isset($_POST['time']) ? $_POST['time'] : '';
$date = isset($_POST['date']) ? $_POST['date'] : '';
$content = isset($_POST['content']) ? $_POST['content'] : '';

// Get user_id based on the provided username
$user_id_query = "SELECT user_id FROM users WHERE username = '$username'";
$result = $conn->query($user_id_query);

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $user_id = $row['user_id'];

    // Insert entry into the 'entries' table
    $sql = "
        INSERT INTO entries (`long`, lat, user_id, time, date, content)
        VALUES ('$long', '$lat', '$user_id', '$time', '$date', '$content');
    ";

    if ($conn->query($sql) === TRUE) {
        // Get the last inserted ID
        $entry_id = $conn->insert_id;

        // Prepare JSON response
        $response = array(
            'status' => 'success',
            'message' => 'Entry added successfully',
            'entry_id' => $entry_id
        );

        // Return JSON response
        echo json_encode($response);
    } else {
        // Prepare JSON response for error
        $response = array(
            'status' => 'error',
            'message' => "Error: " . $sql . "<br>" . $conn->error
        );

        // Return JSON response for error
        echo json_encode($response);
    }
} else {
    // Prepare JSON response for user not found
    $response = array(
        'status' => 'error',
        'message' => "Error: User not found with username '$username'"
    );

    // Return JSON response for user not found
    echo json_encode($response);
}

// Close the database connection
$conn->close();

?>