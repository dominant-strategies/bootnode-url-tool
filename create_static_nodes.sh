#!/bin/bash

# The root directory containing IP-specific folders
enode_dir="enodes"
# The destination directory for the aggregated files
dest_dir="static-nodes"
# A temporary directory for holding enode lists
temp_dir=$(mktemp -d -t enode_tmp_XXXXXX)

# List of all categories and their respective ports
categories=("prime" "region-0" "region-1" "region-2" "zone-0-0" "zone-0-1" "zone-0-2" "zone-1-0" "zone-1-1" "zone-1-2" "zone-2-0" "zone-2-1" "zone-2-2")
ports=(30303 30304 30305 30306 30307 30308 30309 30310 30311 30312 30313 30314 30315)

# Initialize placeholder files for enodes
for category in "${categories[@]}"; do
    touch "$temp_dir/$category"
done

# Iterate over each IP folder
for folder in "$enode_dir"/*; do
    # Ensure it's a directory
    [[ -d "$folder" ]] || continue

    # Extract the enodes from the enode.json file inside the IP folder
    json_file="$folder/enode.json"
    [[ -f "$json_file" ]] || continue

    # For each category, extract and append the enode to the respective temp file
    for index in "${!categories[@]}"; do
        category=${categories[$index]}
        port=${ports[$index]}

        # Use jq to extract the enode entry for the current category from the JSON file
        current_enode=$(jq -r ".[\"$category\"][]?" $json_file 2>/dev/null)
        echo "Extracted for $category: $current_enode"

        # Skip if null, empty, or error occurred
        [[ "$current_enode" == "null" || -z "$current_enode" ]] && continue
        # Append the port to the enode and save to the respective file
        echo "${current_enode}:$port" >> "$temp_dir/$category"
    done
done

# Write unique enodes to the respective files
for category in "${categories[@]}"; do
    mkdir -p "$dest_dir/$category"
    
    # Filter unique enodes and write them to the category's static-nodes.json file
    sort -u "$temp_dir/$category" | jq -R . | jq -s . > "$dest_dir/$category/static-nodes.json"
done

# Clean up the temporary directory
rm -r "$temp_dir"

echo "Aggregated enode files with ports have been created in the static-nodes/ directory."
