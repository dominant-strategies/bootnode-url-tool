#!/bin/bash

# The root directory containing IP-specific folders
enode_dir="enodes"
# The destination directory for the aggregated files
dest_dir="static-nodes"

# List of all categories
categories=("prime" "region-0" "region-1" "region-2" "zone-0-0" "zone-0-1" "zone-0-2" "zone-1-0" "zone-1-1" "zone-1-2" "zone-2-0" "zone-2-1" "zone-2-2")

# Initialize a placeholder array for enodes
declare -a enodes

# Iterate over each IP folder
for folder in "$enode_dir"/*; do
    # Ensure it's a directory
    [[ -d "$folder" ]] || continue

    # Extract the enodes from the enode.json file inside the IP folder
    json_file="$folder/enode.json"
    [[ -f "$json_file" ]] || continue

    # For each category, extract and append the enode to the respective position in the array
    for category in "${categories[@]}"; do
        # Use jq to extract the enode entry for the current category from the JSON file
        current_enode=$(jq -r ".$category[]?" "$json_file" 2>/dev/null)

        # Skip if null, empty, or error occurred
        [[ "$current_enode" == "null" || -z "$current_enode" ]] && continue

        # Append the enode to the array using string manipulation
        enodes["$category"]+="$current_enode "
    done
done

# Write unique enodes to the respective files
for category in "${categories[@]}"; do
    mkdir -p "$dest_dir/$category"
    
    # Get enodes for the category
    category_enodes=($(echo ${enodes["$category"]}))
    
    # Filter unique enodes and write them to the category's static-nodes.json file
    printf '%s\n' "${category_enodes[@]}" | sort -u | jq -R . | jq -s . > "$dest_dir/$category/static-nodes.json"
done

echo "Aggregated enode files have been created in the static-nodes/ directory."
