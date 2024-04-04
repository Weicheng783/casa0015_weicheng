<?php

// Image comparison function using Flask API
function compareImagesWithFlask($image1_path, $image2_path) {
    // URL of the Flask server
    $url = 'http://localhost:5000/compare';

    // Data to be sent in the POST request
    $data = array('image1_path' => "/var/www/html/flutter/pics/" . $image1_path . ".jpg", 'image2_path' => "/var/www/html/flutter/picsCmp/" . $image2_path . ".jpg");
    // Initialize cURL session
    $ch = curl_init();

    // Set cURL options
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));

    // Execute cURL session
    $response = curl_exec($ch);

    // Close cURL session
    curl_close($ch);

    // Decode the JSON response
    $result = json_decode($response, true);

    return $result;
}

// Check if image locations are sent via POST request
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Retrieve image locations from the POST request
    $image1_path = $_POST["image1_path"];
    $image2_path = $_POST["image2_path"];

    // Check if image files exist
    if (!file_exists("/var/www/html/flutter/pics/" . $image1_path . ".jpg") || !file_exists("/var/www/html/flutter/picsCmp/" . $image2_path . ".jpg")) {
        $response = array("error" => "One or both of the images could not be found.");
    } else {
        // Call Flask API for image comparison
        $result = compareImagesWithFlask($image1_path, $image2_path);
        $response = $result;
    }

    // Send the response as JSON
    header('Content-Type: application/json');
    echo json_encode($response);
} else {
    // If not a POST request, return an error
    http_response_code(405);
    echo json_encode(array("error" => "Method not allowed. Please use POST."));
}

?>