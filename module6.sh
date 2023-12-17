#!/bin/bash

backup_dir="/home/abdallah/1"
backup_des="/home/abdallah/2"

mkdir -p $backup_des

for file_path in "$backup_dir"/*; do
    if [ -f "$file_path" ]; then
            cp "$file_path " "$backup_des"

            if [ $? -eq 0 ]; then
                echo "Copied successfully."
            else
                echo "Failed to copy"
            fi
    fi
done
