# How to Create PICO-8 Games with Automated Screenshot/Video Capture

## Quick Commands Reference
```bash
# PICO-8 screenshot setup
pico8 -desktop [path]

# Ctrl+6 to take screenshot in PICO-8
# Ctrl+8 to start GIF recording in PICO-8
# Ctrl+9 to stop GIF recording in PICO-8
# Configure pico8 in Windows PATH environment variables

# Launch game with screenshot folder
pico8 [game.p8] -run -desktop "C:\Users\santi\repos\Mini-Pico-Games\pico-8\carts\screenshots"
```


## Complete Workflow for New Games

### Step 1: Create Game with Automation Support

**PICO-8 File Template Structure:**
```lua
pico-8 cartridge
version 42
__lua__

-- Game Title and Description
-- Author information

function _init()
    -- Initialize game variables
    -- Player properties
    -- Game state setup
end

function _update()
    -- Handle input
    -- Update physics
    -- Update animations
    -- Update camera
end

function _draw()
    cls() -- Clear screen
    -- Draw background
    -- Draw game objects
    -- Draw player
    -- Draw UI
end

-- Additional helper functions

__gfx__
-- MUST be pure hexadecimal data only
-- Each line exactly 32 hex characters (128 pixels wide)
-- Each sprite is 8x8 pixels (8 lines of 8 hex digits each)
-- NO comments allowed in this section

__map__
-- Optional tilemap data (hexadecimal)

__sfx__
-- Optional sound effects data

__music__
-- Optional music data
```

**CRITICAL: PICO-8 Sprite Data Format**
- The `__gfx__` section MUST contain only pure hexadecimal data
- NO comments, NO code, NO explanations within sprite data
- Each line should be exactly 32 hex characters (128 pixels wide)
- Each sprite is 8x8 pixels = 8 lines of 8 hex characters each
- Comments can only go in the Lua `__lua__` section above
- Invalid sprite data will cause compilation errors

### Step 2: Launch and Test
```bash
# Start PICO-8 with proper screenshot setup
"C:\Program Files (x86)\PICO-8\pico8.exe" [GAME_NAME].p8 -run -desktop "C:\Users\santi\repos\Mini-Pico-Games\pico-8\carts\screenshots"
```

### Step 3: Automated Capture (Screenshot or GIF)

**For Screenshots:**
```bash
# Use AutoHotkey for automated character movement and screenshots
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" direct_control.ahk
```

**For GIF Recording:**
```bash
# Use AutoHotkey for GIF recording with character movement
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" gif_recording_control.ahk
```

**Manual Controls:**
- Ctrl+6 = Take screenshot
- Ctrl+8 = Start GIF recording  
- Ctrl+9 = Stop GIF recording

### Step 4: Verify Results
```bash
# Check screenshots and GIFs were created
ls -la screenshots/
find . -name "*.png" -mmin -2  # PNG files from last 2 minutes
find . -name "*.gif" -mmin -2  # GIF files from last 2 minutes
```

## Advanced Prompt for Complex Games

```
Create a [GAME_TYPE] PICO-8 game with [SPECIFIC_FEATURES]. The game should include:

1. Character sprite with [X]-frame animation cycle
2. Arrow key movement controls (essential for automation)
3. [SPECIFIC_GAMEPLAY_ELEMENTS]
4. Visual polish with background and effects

After creating the game:
1. Test manual play with arrow keys
2. Run automation script: "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" direct_control.ahk  
3. Verify screenshots are captured in screenshots/ folder
4. Provide workflow summary and any game-specific notes

Use the existing automation infrastructure:
- AutoHotkey scripts are already set up
- PICO-8 path: "C:\Program Files (x86)\PICO-8\pico8.exe"  
- Screenshot folder: "C:\Users\santi\repos\Mini-Pico-Games\pico-8\carts\screenshots"
- Automation moves character RIGHT 5x, DOWN 3x, LEFT 4x, then screenshots

Requirements: Game must respond to arrow keys for the automation to work properly.
```

## Troubleshooting Automation

**If screenshots don't appear:**
1. Check PICO-8 is running: `tasklist | grep -i pico`
2. Ensure `-desktop` parameter was used when launching
3. Verify AutoHotkey found PICO-8 window
4. Try manual Ctrl+6 in PICO-8 to test screenshot function

**If character doesn't move:**
1. Confirm arrow key controls in `_update()` function
2. Check AutoHotkey script syntax (v2 format)
3. Ensure PICO-8 window has focus before automation

## Files in This Directory
- `direct_control.ahk` - One-shot automation script
- `pico8_control_v2.ahk` - Interactive script with hotkeys
- `walk_cycle_demo.p8` - Working example game
- `screenshots/` - Output folder for captured images
- Various helper scripts and validation tools

This system provides automated sprite documentation for any PICO-8 game with minimal manual setup.