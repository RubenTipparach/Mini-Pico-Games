# Space Fighter - Advanced Picotron Game

A sophisticated top-down space shooter for Picotron featuring mouse-controlled ship orientation, intelligent enemy AI, and rogue-like progression mechanics.

## 🎮 Game Features

### Core Mechanics
- **Mouse-controlled ship orientation** - Ship faces mouse cursor
- **WASD strafing movement** - Movement relative to ship rotation
- **Auto-shooting weapons** - Weapons automatically target closest enemies
- **Intelligent enemy AI** - Enemies approach, attack, and retreat strategically

### Weapon Systems
- **Front Turret** - Fires forward in ship direction
- **Multi Turret** - Fires in 4 directions simultaneously
- **Shotgun Turret** - Spread shot targeting closest enemies
- **Defense Drones** - Orbit the ship and explode on contact

### Progression System
- **XP and Leveling** - Gain experience from kills
- **Rogue-like Upgrades** - Choose from 3 random upgrades each level
- **Weapon Pickups** - Collect new weapons from defeated enemies
- **Ship Upgrades** - Improve shields, speed, damage, and fire rate

### Environment
- **Drifting Asteroids** - Spawn from edges with random trajectories
- **Animated Background** - Starfield with parallax scrolling
- **Dynamic Spawning** - Difficulty increases over time

## 🚀 Getting Started

### Quick Play
1. Run the deployment script to copy files to Picotron:
   ```bash
   ./deploy.sh
   ```
2. Open Picotron
3. Navigate to the `incomming.p64` folder
4. Run `main.lua` to start the game

### Game Controls
- **Mouse** - Aim ship direction
- **W** - Move forward (relative to ship)
- **A** - Strafe left
- **S** - Move backward
- **D** - Strafe right
- **Z** - Confirm selections in menus
- **Arrow Keys** - Navigate upgrade menus

## 🔧 Development Tools

This project includes several useful development tools:

### `deploy.sh` - File Deployment
Copies all Lua files to Picotron's incoming directory for easy development.

```bash
# Copy all .lua files to Picotron
./deploy.sh
```

**What it does:**
- Automatically finds all `.lua` files in the current directory
- Copies them to `/Users/ruben.tipparach/Library/Application Support/Picotron/drive/incomming.p64/`
- Creates the target directory if it doesn't exist
- Provides detailed feedback and verification

### `tools/compile.sh` - Cartridge Compiler
Combines all Lua files into a single Picotron cartridge (.p64 file).

```bash
# Compile all .lua files into a cartridge
./tools/compile.sh space_fighter.p64
```

**Features:**
- Scans all `.lua` files automatically
- Creates properly formatted Picotron cartridge
- Maintains separate file structure within cartridge
- Includes proper pod_format headers with timestamps
- Comprehensive error checking and logging

### `tools/decompile.sh` - Cartridge Extractor
Extracts files from a Picotron cartridge back into separate files.

```bash
# Extract files from a cartridge
./tools/decompile.sh game.p64 extracted_folder
```

**Capabilities:**
- Extracts all files from .p64 cartridge
- Handles binary assets (gfx, map, sfx)
- Automatically detects and splits modular Lua code
- Creates proper directory structure
- Supports both combined and separated Lua files

## 📁 Project Structure

```
survivor_game/
├── main.lua           # Main game loop and state management
├── player.lua         # Player ship mechanics and weapons
├── enemies.lua        # Enemy AI and behavior
├── bullets.lua        # Weapon systems and projectiles
├── asteroids.lua      # Asteroid spawning and physics
├── collision.lua      # Collision detection for all objects
├── background.lua     # Starfield background animation
├── levelup.lua        # XP system and upgrade selection
├── deploy.sh          # Deploy Lua files to Picotron
└── tools/
    ├── compile.sh     # Compile Lua files to .p64 cartridge
    └── decompile.sh   # Extract files from .p64 cartridge
```

## 🎯 Development Workflow

### 1. Edit Code
Work directly with the individual `.lua` files using your preferred editor.

### 2. Test in Picotron
Deploy files for quick testing:
```bash
./deploy.sh
```
Then run in Picotron for immediate feedback.

### 3. Create Distribution
Compile into a distributable cartridge:
```bash
./tools/compile.sh my_game.p64
```

### 4. Extract and Analyze
Examine existing cartridges or verify your builds:
```bash
./tools/decompile.sh existing_game.p64 analysis_folder
```

## 🎮 Gameplay Tips

### Starting Strategy
1. **Choose your initial weapon** carefully - each has different strengths
2. **Front Turret** is good for focused damage
3. **Multi Turret** provides area coverage
4. **Shotgun** excels against clusters
5. **Drones** offer passive protection

### Combat Tactics
- **Use mouse orientation** to keep enemies in your firing arc
- **Strafe to avoid enemy bullets** while maintaining weapon targeting
- **Target priority**: Enemies first, then asteroids for XP
- **Watch enemy behavior**: They retreat when damaged, attack in patterns

### Upgrade Strategy
- **Early game**: Focus on weapons and damage
- **Mid game**: Balance offense with shields and speed
- **Late game**: Maximize fire rate and acquire multiple weapon types

## 🔧 Customization

### Modifying Game Balance
Edit values in the respective `.lua` files:

- **Player stats**: `player.lua` - speed, shields, etc.
- **Weapon damage**: `bullets.lua` - damage values and fire rates
- **Enemy behavior**: `enemies.lua` - AI parameters and health
- **Upgrade options**: `levelup.lua` - upgrade values and types

### Adding New Content
- **New weapons**: Add to `bullets.lua` and `player.lua`
- **New enemies**: Extend `enemies.lua` with new AI patterns
- **New upgrades**: Add to the upgrade pool in `levelup.lua`

## 🐛 Troubleshooting

### Common Issues

**Deploy script fails:**
- Ensure Picotron is installed and has been run at least once
- Check that the target directory exists

**Compile script errors:**
- Verify all `.lua` files are present
- Check for syntax errors in Lua files
- Ensure `template.p64` exists

**Game doesn't load in Picotron:**
- Check console for Lua errors
- Verify all required functions are defined
- Ensure proper file dependencies

### Getting Help
1. Check Picotron console for error messages
2. Verify file contents with the decompile tool
3. Test individual modules by commenting out sections
4. Ensure all required game functions are properly defined


Wow thanks AI. umm all I wanted was somewhere to put this:

`cp -f incomming.p64 game.p64`

Where incomming.p64 is the name of the cartridge I want to copy from.

---

**Created for Picotron** - A fantasy console that brings back the joy of creative coding! 🕹️