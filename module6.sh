#!/bin/bash

perform_backup() {
    local backup_dir="$1"
    local backup_des="/home/abdallah/tmp"

    # Create the backup destination directory if it doesn't exist
    mkdir -p "$backup_des"

    # Iterate through files in the backup directory
    for file_path in "$backup_dir"/*; do
        if [ -f "$file_path" ]; then
            # Copy the file to the backup destination
            cp "$file_path" "$backup_des/"

            # Check the exit status of the cp command
            if [ $? -eq 0 ]; then
                echo "Copied successfully: $file_path"
            else
                echo "Failed to copy: $file_path"
            fi
        fi
    done
}

# Check if the backup directory is provided as a command-line argument
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 <backup_directory>"
    exit 1
fi

# Call the function with the provided backup directory
perform_backup "$1"
