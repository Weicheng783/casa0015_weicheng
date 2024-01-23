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

// Get the username from the POST parameters
$desiredUsername = isset($_POST['username']) ? $_POST['username'] : '';

// Query to fetch user details, entries created, and entries explored
$sql = "
    SELECT
        u.username,
        u.user_id,
        e.entry_id,
        e.`long`,
        e.lat,
        e.time,
        e.date,
        e.content,
        ee.entry_id AS explored_entry_id,
        ee.time AS explored_time,
        ee.date AS explored_date,
        ee.comment
    FROM users u
    LEFT JOIN entries e ON u.user_id = e.user_id
    LEFT JOIN entry_explored ee ON u.user_id = ee.user_id
    WHERE u.username = '$desiredUsername';
";

$result = $conn->query($sql);

if ($result) {
    $userData = array();
    
    while ($row = $result->fetch_assoc()) {
        $userData['username'] = $row['username'];
        $userData['user_id'] = $row['user_id'];
        
        // Entries created by the user
        if (!empty($row['entry_id'])) {
            $userData['entries_created'][] = array(
                'entry_id' => $row['entry_id'],
                'long' => $row['long'],
                'lat' => $row['lat'],
                'time' => $row['time'],
                'date' => $row['date'],
                'content' => $row['content']
            );
        }
        
        // Entries explored by the user
        if (!empty($row['explored_entry_id'])) {
            $userData['entries_explored'][] = array(
                'entry_id' => $row['explored_entry_id'],
                'time' => $row['explored_time'],
                'date' => $row['explored_date'],
                'comment' => $row['comment']
            );
        }
    }
    
    // Remove password from the output
    unset($userData['password']);
    
    // Convert the data to JSON format
    $jsonResponse = json_encode($userData, JSON_PRETTY_PRINT);
    
    // Output the JSON response
    echo $jsonResponse;
} else {
    echo "Error: " . $sql . "<br>" . $conn->error;
}

// Close the database connection
$conn->close();

?>