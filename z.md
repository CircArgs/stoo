#!/bin/bash

# Create a temporary log file
LOG_FILE=$(mktemp --suffix=.log)
OUTPUT_TO_SHELL=true  # Set to false to write only to the file

# Function to handle conditional output
log_message() {
    if $OUTPUT_TO_SHELL; then
        echo "$1" | tee -a "$LOG_FILE"  # Output to both shell & file
    else
        echo "$1" >> "$LOG_FILE"  # Output only to file
    fi
}

# Start capturing logs
kubectl logs -f -n "$NAMESPACE" "$DEV_POD" | while IFS= read -r line; do
    # Variable tracks whether we're installing packages
    [[ -z "$IN_PACKAGE_INSTALL" ]] && IN_PACKAGE_INSTALL=0

    # Check if line has the prefix
    if [[ "$line" == *"[PACKAGE INSTALL]"* ]]; then
        # Announce that we are pausing
        if [[ "$IN_PACKAGE_INSTALL" -eq 0 ]]; then
            log_message "⚠ Installing your packages..."
            log_message "⚠ You'll like to wait for this to complete..."
            IN_PACKAGE_INSTALL=1
        fi
        continue  # Ignore the line
    else
        # If we were installing, announce resumption
        if [[ "$IN_PACKAGE_INSTALL" -eq 1 ]]; then
            log_message "✅ Package installation finished. Resuming logs..."
            IN_PACKAGE_INSTALL=0
        fi
        # Print this line as normal
        log_message "📜 Log: $line"
    fi
done

# Print location of temp log file
echo "Logs saved in: $LOG_FILE"
