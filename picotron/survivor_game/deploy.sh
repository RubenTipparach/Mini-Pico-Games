#!/bin/bash

# Picotron Lua Files Deployment Script
# Copies individual Lua files to Picotron's incoming directory

set -e  # Exit on any error

# Configuration
PICOTRON_INCOMING="/Users/ruben.tipparach/Library/Application Support/Picotron/drive/incomming.p64"

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

log_info "Picotron Lua Files Deployment Script started..."

# Find all Lua files in current directory
LUA_FILES=($(find . -maxdepth 1 -name "*.lua" -type f | sort))

if [ ${#LUA_FILES[@]} -eq 0 ]; then
    log_error "No .lua files found in current directory!"
    exit 1
fi

# Check if Picotron directory exists
PICOTRON_DIR=$(dirname "$PICOTRON_INCOMING")
if [ ! -d "$PICOTRON_DIR" ]; then
    log_error "Picotron directory not found: $PICOTRON_DIR"
    log_info "Make sure Picotron is installed and has been run at least once."
    exit 1
fi

# Create the incoming directory if it doesn't exist
if [ ! -d "$PICOTRON_INCOMING" ]; then
    log_info "Creating incoming directory: $PICOTRON_INCOMING"
    mkdir -p "$PICOTRON_INCOMING"
fi

log_info "Found ${#LUA_FILES[@]} Lua files to copy:"
for file in "${LUA_FILES[@]}"; do
    echo "  - $(basename "$file")"
done

log_info "Target directory: $PICOTRON_INCOMING"

# Copy each Lua file
copied_count=0
for lua_file in "${LUA_FILES[@]}"; do
    filename=$(basename "$lua_file")
    target_path="$PICOTRON_INCOMING/$filename"
    
    log_info "Copying: $filename"
    cp "$lua_file" "$target_path"
    
    # Verify the copy
    if [ -f "$target_path" ]; then
        ((copied_count++))
    else
        log_error "Failed to copy: $filename"
    fi
done

# Summary
if [ $copied_count -eq ${#LUA_FILES[@]} ]; then
    log_success "All files copied successfully!"
    log_info "$copied_count Lua files are now available in Picotron"
    echo ""
    echo "======================== INSTRUCTIONS ========================"
    echo "1. Open Picotron"
    echo "2. Navigate to the 'incomming.p64' folder in your drive"
    echo "3. Your Lua files should be available there:"
    for file in "${LUA_FILES[@]}"; do
        echo "   - $(basename "$file")"
    done
    echo "4. You can now work with these files directly in Picotron"
    echo "=========================================================="
else
    log_warning "Only $copied_count out of ${#LUA_FILES[@]} files copied successfully"
fi

echo ""
log_info "Deployment complete! 📁"