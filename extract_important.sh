#!/bin/bash

# Define the URL of the file you want to download
URL="https://weicheng.app/flutter/AndroidManifest.xml"

# Define the destination folder where you want to save the file
DESTINATION_FOLDER="./android/app/src/main/AndroidManifest.xml"

# Use wget to download the file and save it to the destination folder
wget -P "$DESTINATION_FOLDER" "$URL"