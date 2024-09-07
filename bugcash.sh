#!/bin/bash

#Bugcrowd Attack Surface Hosts [Bugcash]
#V1.1
#09032024
#BY D3N14LD15K

# Function to extract engagements from the Bugcrowd API with error handling
extract_engagements() {
    local page=$1
    local cookie=$2
    local category=$3

    # Set the API URL based on the selected category
    local url="https://bugcrowd.com/engagements.json?category=${category}&page=$page&sort_by=promoted&sort_direction=desc"

    # Make the request with the session cookie header
    local response=$(curl -s -H "Cookie: $cookie" -H "Accept: application/json" "$url")

    # Check if the response is in valid JSON format and extract engagements
    local engagements=$(echo "$response" | jq '.engagements[]?')
    if [ -z "$engagements" ]; then
        echo "No more engagements found on page $page. Exiting."
        return 1
    fi

    # Extract and display the brief URLs of engagements
    echo "Extracted URLs on page $page:"
    echo "$engagements" | jq -r '.briefUrl' | sed 's|^|https://bugcrowd.com|'

    # Append the complete URLs of engagements to the output file
    echo "$engagements" | jq -r '.briefUrl' | sed 's|^|https://bugcrowd.com|' >> engagements.txt
}

# Check for the required flags and set the category accordinglyi


if [[ "$1" == "-vdp" ]]; then
    category="vdp"
elif [[ "$1" == "-bbp" ]]; then
    category="bug_bounty"
else
    echo "Usage: $0 -vdp for category=vdp or -bbp for category=bug_bounty"
    exit 1
fi

# Ask for the session cookie from the user
read -p "Enter the cookie for authentication: " cookie

# Initialize the page number
page=1

# Create or clear the output file
> engagements.txt

# Loop through pages to extract engagements
while true; do
    # Extract engagements for the current page
    if ! extract_engagements $page "$cookie" "$category"; then
        break
    fi

    # Increment the page number for the next request
    ((page++))
done

# Sorting and cleaning up extracted URLs (keeping the rest of your script intact)
touch vdp.tmp
cat engagements.txt | sort > vdp.tmp; rm engagements.txt; mv vdp.tmp engagements.txt

echo "Extraction complete. All URLs listed in engagements.txt"

input_file="engagements.txt"

# File to store valid targets
output_file="scope.txt"
temp_file="temp_valid_targets.txt"

# Create or clear the output file
> "$output_file"

# Function to extract targets_url from a response
extract_targets_url() {
    local response="$1"

    # Extract the JSON part after "in_scope":true," and before the next "},{"id":
    local json_segment=$(echo "$response" | awk -F'"in_scope":true,"' '{print $2}' | awk -F'","id":"' '{print $1}')

    # Extract the targets_url from the JSON segment
    echo "$json_segment" | awk -F'"targets_url":"' '{print $2}' | awk -F'"' '{print $1}'
}

# Function to fetch valid targets from a given base URL
fetch_valid_targets() {
    local base_url="$1"
    local cookie="$2"

    # Append /target_groups to the URL
    target_groups_url="${base_url}/target_groups"
    echo "[DEBUG] Fetching target groups from: $target_groups_url"

    # First CURL request to fetch the target groups
    response=$(curl -s -b "$cookie" "$target_groups_url")
    # Removed verbose response debug
    # echo "[DEBUG] Response from $target_groups_url: $response"

    # Check if the response is empty
    if [ -z "$response" ]; then
        echo "[ERROR] No response from $target_groups_url. Check the cookie or URL."
        return
    fi

    # Extract targets_url
    targets_url=$(extract_targets_url "$response")

    # Debug output for the extracted targets_url
    echo "[DEBUG] Extracted targets_url: $targets_url"

    # Check if targets_url was found
    if [ -n "$targets_url" ]; then
        # Construct the full URL for the second CURL request
        full_targets_url="https://bugcrowd.com/${targets_url#\/}"
        echo "[DEBUG] Fetching target details from: $full_targets_url"

        # Second CURL request to fetch the detailed target information
        target_response=$(curl -s -b "$cookie" "$full_targets_url")
        # Removed verbose response debug
        # echo "[DEBUG] Response from $full_targets_url: $target_response"

        # Check if the target response is empty
        if [ -z "$target_response" ]; then
            echo "[ERROR] No response from $full_targets_url. Check the cookie or URL."
            return
        fi

        # Extract valid targets from the response
        echo "[DEBUG] Extracting valid targets from response..."
        echo "$target_response" | awk -F'"name":' '
        /"name":/ {
            split($0, a, "},")
            for (i in a) {
                if (a[i] ~ /"name":"[^"]+"/) {
                    match(a[i], /"name":"([^"]+)"/, name_match)
                    match(a[i], /"uri":"([^"]*)"/, uri_match)
                    name = name_match[1]
                    uri = uri_match[1]
                    # Always write the name and uri to the file
                    if (name) {
                        print "[DEBUG] Valid target name found: " name
                        print name >> "'"$temp_file"'"
                    }
                    if (uri) {
                        print "[DEBUG] Valid target found: " uri
                        print uri >> "'"$temp_file"'"
                    }
                }
            }
        }'
    else
        echo "[ERROR] No in-scope targets found for $base_url."
    fi
}


input_file="engagements.txt"
temp_input_file="temp_input.txt" # Temporary file to store modified input

# Remove the word "engagements" from the input file and save it to a temporary file
sed 's/engagements//g' "$input_file" > "$temp_input_file"

# Read URLs from the modified input file
while IFS= read -r url; do
    # Skip empty lines
    if [ -n "$url" ]; then
        echo "[DEBUG] Processing URL: $url"
        fetch_valid_targets "$url" "$cookie"
    fi
done < "$temp_input_file"

# Convert content to lowercase and save it to the final output file
cat "$temp_file" | tr '[:upper:]' '[:lower:]' > "$output_file"

# Remove the temporary files
rm "$temp_file" "$temp_input_file"


grep -E '(\*|([a-zA-Z0-9._%+-]+\.[a-zA-Z]{2,})|https?://|[0-9]{1,3}(\.[0-9]{1,3}){3})' scope.txt | grep -Ev '(apple\.com|google\.com)' > cleaned_valid_targets.txt

rm scope.txt

sed 's#https\?://##' cleaned_valid_targets.txt | sort -u > scope.txt

sed 's#/$##' scope.txt > cleaned_tmp.txt

sed 's/ //g' cleaned_tmp.txt > vdp_nonengagement_inscope.txt

sed 's#http(s)://##g' vdp_nonengagement_inscope.txt  > output_file.txt; cat output_file.txt | sort -u > bugcrowd_inscope.txt 

sed 's/^\*\([^\.]\)/*.\1/' bugcrowd_inscope.txt > bgtmp.tmp


rm bugcrowd_inscope.txt ; mv bgtmp.tmp bugcrowd_inscope.txt ; rm cleaned_valid_targets.txt; rm cleaned_tmp.txt; rm output_file.txt; rm scope.txt; rm vdp_nonengagement_inscope.txt


# Define input and output files
input_file="bugcrowd_inscope.txt"
ips_file="inscope-others.txt"

# Check if the input file is empty
if [ ! -s "$input_file" ]; then
    echo "Input file $input_file is empty or does not exist."
    exit 1
fi

# Display the input file content for debugging
echo "Input file content:"
cat "$input_file"

# Extract IP addresses and specific IP range entries, saving them to inscope_ips.txt
grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|:.*and.*' "$input_file" > "$ips_file"

mv bugcrowd_inscope.txt inscope.tmp

sed -e 's/(readbelowfordetails)//g' \
    -e 's/\/\*//g' \
    -e 's/(dnsservice;dnsrelated)//g' \
    -e 's/{app-id}//g' \
    -e 's/\\t//g' \
    -e 's/\/.*//g' inscope.tmp > pre.txt

sort -u pre.txt > scope.txt

echo "Scan complete."
