# Bugcrowd Attack Surface Harvester [Bugcash]

**Version**: 1.1  
**Date**: 09/03/2024  
**Author**: D3N14LD15K  

## Overview

Bugcrowd Attack Surface Harvester (Bugcash) is a Bash script designed to extract in-scope targets from Bugcrowd's Bug Bounty Programs (BBP) or Vulnerability Disclosure Programs (VDP). The script fetches the list of engagements from Bugcrowd, identifies valid targets, and stores them in a text file.

## Features

- Extracts engagements from Bugcrowd based on selected categories (`BBP` or `VDP`).
- Collects URLs of engagements
- Fetches in-scope targets
- Identifies IP addresses and specific IP ranges from the extracted data.

## Requirements

- **Bash**: To run the script on Unix-like systems.
- **cURL**: To perform network requests to Bugcrowd’s API.
- **jq**: To parse and manipulate JSON data from API responses.

## Installation

Ensure `cURL` and `jq` are installed on your system:

```bash
git clone https://github.com/D3N14LD15K/Bugcash.git
cd bugcash
```

## Usage
The script requires a session cookie from Bugcrowd for authentication. Choose between Bug Bounty Programs (BBP) or Vulnerability Disclosure Programs (VDP) to extract engagements.

```Command Syntax

./bugcash.sh

```

## Steps
Run the script and select the type of program. 1 for BBP or 2 for VDP.
Enter the session cookie when prompted for authentication.
The script extracts engagement URLs and in-scope targets.

## Output files
engagements.txt: Contains a list of extracted engagement URLs.

scope.txt: Final list of valid in-scope targets (domains, IP addresses).

## Debugging
Debug messages are displayed during execution to help track script progress, such as URLs being processed and extracted targets. This information is useful for troubleshooting if the script doesn't perform as expected.

## Error handling
The script checks for valid JSON responses from Bugcrowd’s API.
Handles empty or incorrect API responses gracefully, notifying the user when engagements or targets are not found.

## Disclaimer
Use this script responsibly within the terms of Bugcrowd's platform. Ensure that you have permission to access the engagements and that your activities comply with safe harbor policies.

## License
This script is provided "as-is" without any warranties. It may incur in some errors, especially with non standard formatted targets. Use at your own risk.
