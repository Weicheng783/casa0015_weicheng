<?php
// Directory to save the pictures
$uploadDirectory = '/var/www/html/flutter/picsCmp/';

// Handle the HTTPS POST request
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Check if files were uploaded
    if (isset($_FILES['photos']) && is_array($_FILES['photos']['name']) && count($_FILES['photos']['name']) > 0) {
        // Save only the first file
        $file_name = $_FILES['photos']['name'][0];
        $file_tmp = $_FILES['photos']['tmp_name'][0];
        $file_extension = pathinfo($file_name, PATHINFO_EXTENSION);

        // Generate a unique filename
        $unique_id = uniqid();
        $random_string = bin2hex(random_bytes(5)); // Generate a random string
        $new_file_name = $uploadDirectory . $unique_id . '_' . $random_string . '.' . $file_extension;

        // Move the uploaded file to the destination directory
        if (move_uploaded_file($file_tmp, $new_file_name)) {
            // Return the address of the saved file
            echo json_encode(array('file_address' => $unique_id . '_' . $random_string));
        } else {
            // If unable to move file, return an error
            http_response_code(500); // Internal Server Error
            echo json_encode(array('error' => 'Failed to save file.'));
        }
    } else {
        // If no files were uploaded, return an error
        http_response_code(400); // Bad Request
        echo json_encode(array('error' => 'No files uploaded.'));
    }
} else {
    // Handle other HTTP methods or provide an error message
    http_response_code(405); // Method Not Allowed
    echo json_encode(array('error' => 'Only POST requests are allowed.'));
}
?>