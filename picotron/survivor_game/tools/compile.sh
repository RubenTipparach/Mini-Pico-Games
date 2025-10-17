#!/bin/bash

# Picotron Lua Compiler
# General-purpose tool that scans all .lua files in the current directory
# and combines them into a Picotron cartridge (.p64 file)

set -e  # Exit on any error

# Configuration
TEMPLATE_FILE="template.p64"
TEMP_FILE="temp_combined.lua"
OUTPUT_FILE="${1:-game.p64}"  # Use first argument or default to game.p64

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    log_error "Template file '$TEMPLATE_FILE' not found!"
    log_info "Please ensure you have a template.p64 file in the current directory."
    exit 1
fi

log_info "Picotron Lua Compiler started..."
log_info "Template: $TEMPLATE_FILE"
log_info "Output: $OUTPUT_FILE"

# Find all .lua files in current directory
LUA_FILES=($(find . -maxdepth 1 -name "*.lua" -type f | sort))

if [ ${#LUA_FILES[@]} -eq 0 ]; then
    log_error "No .lua files found in current directory!"
    exit 1
fi

log_info "Found ${#LUA_FILES[@]} Lua files:"
for file in "${LUA_FILES[@]}"; do
    echo "  - $(basename "$file")"
done

# Start with the base template
cp "$TEMPLATE_FILE" "$OUTPUT_FILE"
log_info "Copied template to output file"

# Create separate Lua files in cartridge
log_info "Building cartridge with separate Lua files..."

current_time=$(date '+%Y-%m-%d %H:%M:%S')
TEMP_OUTPUT="${OUTPUT_FILE}.building"

# Start with template sections (everything before main.lua)
sed '/^:: main\.lua$/,$d' "$OUTPUT_FILE" > "$TEMP_OUTPUT"

# Add each Lua file as a separate section
for lua_file in "${LUA_FILES[@]}"; do
    filename=$(basename "$lua_file")
    log_info "Adding: $filename"
    
    # Add section header and content following Picotron format with proper line breaks
    echo "" >> "$TEMP_OUTPUT"  # Ensure previous section ends with newline
    echo ":: $filename" >> "$TEMP_OUTPUT"
    echo "--[[pod_format=\"raw\",created=\"$current_time\",modified=\"$current_time\",revision=0]]" >> "$TEMP_OUTPUT"
    cat "$lua_file" >> "$TEMP_OUTPUT"
done

# Add the final sections (.info.pod and [eoc]) with proper line break
echo "" >> "$TEMP_OUTPUT"  # Ensure previous section ends with newline
sed -n '/^:: \.info\.pod$/,$p' "$OUTPUT_FILE" >> "$TEMP_OUTPUT"

# Replace the output file
mv "$TEMP_OUTPUT" "$OUTPUT_FILE"

# Calculate total size
total_size=0
for lua_file in "${LUA_FILES[@]}"; do
    file_size=$(wc -c < "$lua_file")
    total_size=$((total_size + file_size))
done

log_info "Total Lua code size: $total_size bytes"

if [ $total_size -gt 65536 ]; then
    log_warning "Total Lua code is quite large ($total_size bytes). Consider optimizing."
fi

# Final verification
if [ -f "$OUTPUT_FILE" ]; then
    output_size=$(wc -c < "$OUTPUT_FILE")
    log_success "Compilation complete!"
    log_info "Generated: $OUTPUT_FILE ($output_size bytes)"
    
    # Show summary
    echo ""
    echo "======================== SUMMARY ========================"
    echo "Input files: ${#LUA_FILES[@]} Lua files"
    echo "Output file: $OUTPUT_FILE"
    echo "Template used: $TEMPLATE_FILE"
    echo "Status: Ready for Picotron"
    echo "========================================================"
    echo ""
    echo "To run in Picotron:"
    echo "1. Copy $OUTPUT_FILE to your Picotron carts directory"
    echo "2. Load the cartridge in Picotron"
    echo "3. Enjoy your game!"
    
else
    log_error "Failed to generate output file!"
    exit 1
fi