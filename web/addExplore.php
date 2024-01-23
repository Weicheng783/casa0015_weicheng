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
$user_identifier = isset($_POST['user_identifier']) ? $_POST['user_identifier'] : '';
$entry_id = isset($_POST['entry_id']) ? $_POST['entry_id'] : '';
$time = isset($_POST['time']) ? $_POST['time'] : '';
$date = isset($_POST['date']) ? $_POST['date'] : '';
$comment = isset($_POST['comment']) ? $_POST['comment'] : '';

// Get user_id and username from either username or user_id
$user_query = "SELECT user_id, username FROM users WHERE username = '$user_identifier' OR user_id = '$user_identifier'";
$user_result = $conn->query($user_query);

if ($user_result->num_rows > 0) {
    $user_row = $user_result->fetch_assoc();
    $user_id = $user_row['user_id'];
    $username = $user_row['username'];

    // Insert entry exploration into the 'entry_explored' table
    $sql = "
        INSERT INTO entry_explored (user_id, entry_id, time, date, comment)
        VALUES ('$user_id', '$entry_id', '$time', '$date', '$comment');
    ";

    if ($conn->query($sql) === TRUE) {
        echo "Exploration added successfully for user: $username (ID: $user_id)";
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }
} else {
    echo "User not found.";
}

// Close the database connection
$conn->close();

?>