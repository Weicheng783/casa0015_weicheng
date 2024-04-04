<?php
// Establish connection to the database
$servername = "localhost";
$username = "xxxx";
$password = "xxxx";
$dbname = "flutter_app";
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if mode is provided via POST
if(isset($_POST['mode'])) {
    $mode = $_POST['mode'];

    // Perform action based on the mode
    switch($mode) {
        case "find":
            findEntries();
            break;
        case "insert":
            insertEntry();
            break;
        case "update":
            updateEntry();
            break;
        default:
            echo json_encode(array("message" => "Invalid mode"));
            break;
    }
} else {
    echo json_encode(array("message" => "No mode provided"));
}

// Function to find entries based on criteria
function findEntries() {
    global $conn;
    if(isset($_POST['message']) || isset($_POST['sender']) || isset($_POST['receiver']) || isset($_POST['status'])) {
        // Initialize an array to store conditions
        $conditions = array();

        // Build conditions based on provided criteria
        if(isset($_POST['message'])) {
            $conditions[] = "message = '" . $_POST['message'] . "'";
        }
        if(isset($_POST['sender'])) {
            $conditions[] = "sender = '" . $_POST['sender'] . "'";
        }
        if(isset($_POST['receiver'])) {
            $conditions[] = "receiver = '" . $_POST['receiver'] . "'";
        }
        if(isset($_POST['status'])) {
            $conditions[] = "status = '" . $_POST['status'] . "'";
        }

        // Combine conditions into a single string
        $condition_str = implode(" AND ", $conditions);

        // Perform query based on the conditions
        $sql = "SELECT * FROM device WHERE " . $condition_str;
        $result = $conn->query($sql);

        $entries = array();

        if ($result->num_rows > 0) {
            // Output data of each row
            while($row = $result->fetch_assoc()) {
                // Add entry to the entries array
                $entries[] = $row;
            }
            // Output the entries array as JSON
            echo json_encode($entries);
        } else {
            echo json_encode(array("message" => "No results found"));
        }
    } else {
        echo json_encode(array("message" => "No criteria provided"));
    }
}

// Function to insert a new entry
function insertEntry() {
    global $conn;
    // Check if necessary data is provided
    if(isset($_POST['message']) && isset($_POST['sender']) && isset($_POST['receiver']) && isset($_POST['status'])) {
        // Prepare statement for insertion
        $stmt = $conn->prepare("INSERT INTO device (message, sender, receiver, status) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("ssss", $_POST['message'], $_POST['sender'], $_POST['receiver'], $_POST['status']);

        // Execute insertion
        if ($stmt->execute()) {
            // Get the ID of the inserted row
            $inserted_id = $stmt->insert_id;
            echo json_encode(array("message" => "Entry inserted successfully", "id" => $inserted_id));
        } else {
            echo json_encode(array("message" => "Error inserting entry"));
        }
    } else {
        echo json_encode(array("message" => "Insufficient data provided for insertion"));
    }
}

// Function to update an existing entry
function updateEntry() {
    global $conn;
    // Check if necessary data is provided
    if(isset($_POST['id']) && (isset($_POST['message']) || isset($_POST['sender']) || isset($_POST['receiver']) || isset($_POST['status']))) {
        // Initialize an array to store update fields
        $update_fields = array();

        // Build the update fields based on provided data
        if(isset($_POST['message'])) {
            $update_fields[] = "message = '" . $_POST['message'] . "'";
        }
        if(isset($_POST['sender'])) {
            $update_fields[] = "sender = '" . $_POST['sender'] . "'";
        }
        if(isset($_POST['receiver'])) {
            $update_fields[] = "receiver = '" . $_POST['receiver'] . "'";
        }
        if(isset($_POST['status'])) {
            $update_fields[] = "status = '" . $_POST['status'] . "'";
        }

        // Combine update fields into a single string
        $update_str = implode(", ", $update_fields);

        // Prepare statement for update
        $sql = "UPDATE device SET " . $update_str . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $_POST['id']);

        // Execute update
        if ($stmt->execute()) {
            echo json_encode(array("message" => "Entry updated successfully"));
        } else {
            echo json_encode(array("message" => "Error updating entry"));
        }
    } else {
        echo json_encode(array("message" => "Insufficient data provided for update or no message ID provided"));
    }
}

$conn->close();
?>