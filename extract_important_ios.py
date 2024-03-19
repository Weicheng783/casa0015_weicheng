import os
import re

# Read the template file
template_file_path = "ios/Runner/AppDelegate.swift"
with open(template_file_path, "r") as file:
    template_content = file.read()

# Extract the Google Map API key from GitHub Secrets
google_map_secret = os.environ.get("Google_Map_Secret")

# Replace the placeholder with the actual Google Map API key
modified_content = re.sub(r'GMSServices.provideAPIKey("xxxxx")', f'GMSServices.provideAPIKey("{google_map_secret}")', template_content)

# Write the modified content back to the file
with open(template_file_path, "w") as file:
    file.write(modified_content)

print("Google Map API key has been successfully added to AppDelegate.swift.")