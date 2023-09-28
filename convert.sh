#!/bin/bash

file="keys.yml"

# Check if file exists
if [[ ! -f $file ]]; then
    echo "File $file not found!"
    exit 1
fi

# Process each line from the file
while IFS=: read -r ip value; do
    # Skip empty lines or lines without expected format
    [[ -z $ip || -z $value ]] && continue
    
    # Strip quotes from value
    value=$(echo "$value" | tr -d '" ')

    # Ensure IP specific directory exists
    mkdir -p "keys/$ip"

    # Write the value to a file
    echo "$value" > "keys/$ip/nodekey"
done < "$file"

echo "Files have been created."
