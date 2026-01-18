#!/bin/bash

# Get the directory where the script is being called from
SCRIPT_DIR=$(pwd)
# echo "Script directory: $SCRIPT_DIR"

# Generate a filename based on the current date and time
TIMESTAMP=$(date -Iseconds | sed 's/-//g; s/://g; s/T/_/; s/+.*//')
FILENAME="benchmarks_$TIMESTAMP.html"

# If bechmarks*.html exists, move it to the .old_benchmarks directory
# Enable nullglob so the glob expands to nothing if no matches
shopt -s nullglob

# Loop through matching files
for file in benchmarks*.html; do
    # Create the directory if it doesn't exist
    mkdir -p .old_benchmarks/b4_$TIMESTAMP
    mkdir -p .old_benchmarks/b4_$TIMESTAMP/benchmarks_files
    
    mv benchmarks_files/* .old_benchmarks/b4_$TIMESTAMP/benchmarks_files/
    mv benchmarks_files/.* .old_benchmarks/b4_$TIMESTAMP/benchmarks_files/
    mv "$file" .old_benchmarks/b4_$TIMESTAMP/
done


# Render the benchmarks.qmd file to HTML and output to the filename
quarto render benchmarks.qmd --to html --output "$FILENAME"

