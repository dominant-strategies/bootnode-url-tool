#!/bin/bash

# Directory containing the nodekey files
key_dir="keys"

# Check if key directory exists
if [[ ! -d $key_dir ]]; then
    echo "Directory $key_dir not found!"
    exit 1
fi

# Create enodes directory if it doesn't exist
mkdir -p enodes

# Iterate over each IP directory inside the key_dir
for folder in "$key_dir"/*; do
    # Ensure it's a directory
    if [[ -d "$folder" ]]; then
        # Extract IP from the folder name
        ip=$(basename "$folder")

        echo "Processing IP: $ip"

        # Ensure IP specific directory exists in enodes
        mkdir -p "enodes/$ip"

        # Run the quai-bootnode-util command and redirect output to the respective enode file
        ./quai-bootnode-util "$folder/nodekey" | tr -d '\n' > "enodes/$ip/enode.json"
    fi
done

echo "Enode files have been created in the enodes/ directory."
