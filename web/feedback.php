<?php

$servername = "localhost";
$username = "root";
$password = "xxxx";
$database = "flutter_app";

// Create connection
$conn = new mysqli($servername, $username, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Retrieve data from Flutter app
$message = $_POST["message"];
$buildVersion = $_POST["build"];
$deviceDetails = $_POST["device_details"];

// Prepare SQL statement
$sql = "INSERT INTO feedback_table (message, build_version, device_details) VALUES (?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $message, $buildVersion, $deviceDetails);

// Execute the statement
if ($stmt->execute()) {
    // Feedback successfully inserted
    $response["status"] = "success";
    $response["message"] = "Feedback submitted successfully!";
    $response["feedback_id"] = $conn->insert_id; // Provide the feedback_id to the Flutter app
} else {
    // Failed to insert feedback
    $response["status"] = "error";
    $response["message"] = "Failed to submit feedback. Please try again later.";
}

// Close connections
$stmt->close();
$conn->close();

// Return the response as JSON
header('Content-Type: application/json');
echo json_encode($response);

?>