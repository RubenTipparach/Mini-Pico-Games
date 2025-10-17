-- LANDER'S REVENGE - Configuration File
-- All configurable values and sprite replacements

-- =======================
-- DEBUG CONFIGURATION
-- =======================
debug_mode = false  -- Set to true to show debug info

-- =======================
-- GAME OPTIONS
-- =======================
game_options = {
    skip_intro = false,      -- Set to true to skip opening cutscene
    selected_primary = 1,    -- Default primary weapon (1-5)
    selected_secondary = 1,  -- Default secondary weapon (1-3)
}

-- =======================
-- SPRITE REPLACEMENTS
-- =======================
-- Set to true to use sprites, false for vector art
-- When using sprites, place them in the sprites folder
sprites = {
    use_sprites = true,   -- Enable sprites
    
    -- Player ship sprite (32x32)
    player_ship = 1,      -- Use sprite 0
    player_thrust = nil,  -- Thrust effect sprite
    
    -- Enemy sprites
    enemy_guard = 8,     -- Guard enemy sprite
    
    -- UI elements
    fuel_bar_bg = nil,   -- Fuel bar background
    fuel_bar_fill = nil, -- Fuel bar fill
    
    -- Terrain and environment
    landing_pad = 2,     -- Landing pad sprite (32x8)
    terrain_tile = nil,  -- Terrain texture
    building_1 = 3,      -- Background building sprite (32x64)
    building_2 = 4,      -- Background building sprite (32x64)
    
    -- Effects
    explosion = nil,     -- Explosion sprite
    bullet_player = nil, -- Player bullet sprite
    bullet_enemy = nil,  -- Enemy bullet sprite
}

-- =======================
-- PLAYER CONFIGURATION
-- =======================
player_config = {
    -- Starting position - Start on first landing pad
    start_x = 250,  -- First landing pad position (1 * 200 + 50)
    start_y = 50,   -- High enough above terrain to be on the pad
    
    -- Physics - Heavier, more realistic feel
    thrust_power = 0.15,     -- Reduced thrust for heavier feel
    turn_speed = 0.08,       -- Slower turning for realism
    gravity = 0.08,          -- Stronger gravity for more challenge
    drag = 0.985,            -- More drag to require constant control
    
    -- Resources
    starting_fuel = 400,     -- Increased from 100 for longer flights
    starting_health = 500,
    fuel_consumption = 0.5,  -- Fuel used per thrust frame
    
    -- Combat
    starting_armor = 1.0,    -- Damage reduction multiplier
    size = 16,               -- Collision radius (32x32 sprite / 2)
    
    -- Weapons
    weapon_damage = 10,      -- Base bullet damage
    weapon_rate = 0.2,       -- Time between shots (seconds)
    weapon_range = 200,      -- Bullet lifetime in pixels (increased from 100)
    bullet_speed = 5,        -- Bullet velocity
    max_shooting_range = 250, -- Maximum range to auto-target enemies
    
    -- Visual
    ship_color = 7,          -- White
    thrust_color_1 = 9,      -- Orange
    thrust_color_2 = 10,     -- Yellow
}

-- =======================
-- ENEMY CONFIGURATION
-- =======================
enemy_config = {
    -- Spawning
    max_enemies = 8,         -- Max enemies on screen (increased from 3)
    spawn_chance = 3,        -- Base spawn chance per frame (%) (increased from 1)
    spawn_chance_per_level = 1.0, -- Additional spawn chance per level (increased from 0.5)
    spawn_distance = 200,    -- Max distance from player to spawn
    
    -- Stats
    base_health = 30,        -- Starting enemy health
    health_per_level = 10,   -- Additional health per level
    move_speed = 0.02,       -- Movement speed toward player
    drag = 0.95,             -- Enemy movement drag
    
    -- Combat
    shoot_cooldown = 60,     -- Frames between enemy shots
    shoot_range = 150,       -- Max range to shoot at player
    bullet_damage = 15,      -- Damage enemy bullets deal
    bullet_speed = 1.5,      -- Enemy bullet speed (reduced from 3 for dodging)
    bullet_lifetime = 50,    -- Enemy bullet range
    collision_damage = 10,   -- Damage from touching enemy
    approach_distance = 100, -- Distance enemies try to maintain from player
    
    -- Visual
    body_color = 2,          -- Red
    outline_color = 8,       -- Dark grey
    bullet_color = 2,        -- Red bullets
    size = 6,                -- Half-width/height
}

-- =======================
-- WORLD CONFIGURATION
-- =======================
world_config = {
    -- Terrain
    terrain_width = 500,     -- Number of terrain points
    terrain_spacing = 4,     -- Pixels between terrain points
    terrain_min_height = 180, -- Minimum terrain height (lowered from 150)
    terrain_max_height = 220, -- Maximum terrain height (lowered from 250)
    terrain_variation = 8,    -- Max height change per step (reduced for smoother terrain)
    terrain_color = 5,       -- Dark grey for main level
    terrain_fill_color = 5,  -- Dark grey (same as outline)
    horizon_color = 20,      -- Color index 20 for distant background
    horizon_height = 60,     -- Height of horizon rectangle
    
    -- Landing pads
    landing_pads_per_level = 5, -- Number of pads per level
    landing_pad_spacing = 200,  -- Distance between pads (increased from 100)
    landing_pad_width = 16,     -- Half-width of landing pad (32/2)
    landing_pad_height = 8,     -- Height of landing pad platform
    landing_pad_support_height = 12, -- Height of support columns
    landing_tolerance = 30,     -- Distance tolerance for landing
    velocity_tolerance = 1,     -- Max velocity for safe landing
    pad_inactive_color = 11,    -- Light grey
    pad_active_color = 8,       -- Red (blinks)
    pad_support_color = 6,      -- Grey supports
    landing_cooldown_distance = 100, -- Distance player must travel before re-triggering same pad
    
    -- Camera
    camera_smooth = 1.0,     -- Camera following speed (1.0 = instant)
    
    -- Starfield background
    star_count = 150,        -- Number of stars
    star_colors = {7, 6, 5}, -- White, light grey, dark grey
    star_parallax = 0.1,     -- Parallax scrolling factor
    
    -- Background objects
    bg_object_count = 20,    -- Number of background objects
    bg_mountain_count = 8,   -- Number of distant mountains
    bg_outpost_count = 6,    -- Number of outposts
    bg_rocket_count = 4,     -- Number of rockets
}

-- =======================
-- UI CONFIGURATION
-- =======================
ui_config = {
    -- Fuel bar
    fuel_bar_x = 10,
    fuel_bar_y = 10,
    fuel_bar_width = 100,
    fuel_bar_height = 8,
    fuel_bar_bg_color = 1,     -- Dark blue
    fuel_bar_border_color = 7, -- White
    fuel_good_color = 11,      -- Light green
    fuel_warning_color = 9,    -- Orange
    fuel_critical_color = 8,   -- Red
    fuel_warning_threshold = 25,
    fuel_critical_threshold = 10,
    
    -- Health bar
    health_bar_x = 10,
    health_bar_y = 30,
    health_bar_width = 100,
    health_bar_height = 8,
    health_bar_bg_color = 1,
    health_bar_border_color = 7,
    health_good_color = 11,
    health_warning_color = 9,
    health_critical_color = 8,
    health_warning_threshold = 50,
    health_critical_threshold = 25,
    
    -- Text colors
    text_primary = 7,        -- White
    text_secondary = 6,      -- Light grey
    text_warning = 9,        -- Orange
    text_error = 8,          -- Red
    text_success = 11,       -- Light green
    text_highlight = 12,     -- Light blue
}

-- =======================
-- UPGRADE CONFIGURATION
-- =======================
upgrade_config = {
    -- Upgrade amounts
    thrust_increase = 0.1,
    fuel_increase = 50,
    armor_increase = 0.2,
    health_increase = 25,
    damage_increase = 5,
    rate_improvement = 0.05, -- Reduces shot cooldown
    range_increase = 20,
    
    -- UI
    upgrades_per_choice = 3, -- Number of upgrade options shown
    selection_color = 7,     -- White
    unselected_color = 6,    -- Light grey
    description_color = 5,   -- Dark grey
    cursor_color = 8,        -- Red
}

-- =======================
-- DIALOG CONFIGURATION
-- =======================
dialog_config = {
    -- Dialog box
    box_x = 50,
    box_y = 350,
    box_width = 380,
    box_height = 100,
    box_bg_color = 1,        -- Dark blue
    box_border_color = 7,    -- White
    
    -- Text
    speaker_color = 7,       -- White
    text_color = 6,          -- Light grey
    continue_color = 12,     -- Light blue
    text_x_offset = 10,
    text_y_offset = 10,
    
    -- Story progression
    dialog_every_n_levels = 3, -- Show story dialog every N levels
}

-- =======================
-- EFFECTS CONFIGURATION
-- =======================
effects_config = {
    -- Particles
    thrust_particles_per_frame = 1,
    explosion_particles = 10,
    particle_colors = {9, 10, 7}, -- Orange, yellow, white
    
    -- Thrust effect
    thrust_spread = 0.25,    -- Angle variation
    thrust_distance = 10,    -- Distance behind ship
    thrust_speed_min = 1,
    thrust_speed_max = 3,
    thrust_life = 10,        -- Particle lifetime
    
    -- Explosion effect
    explosion_speed_min = 1,
    explosion_speed_max = 4,
    explosion_life = 20,
}

-- =======================
-- INPUT CONFIGURATION
-- =======================
input_config = {
    -- WASD Key mappings (Picotron key codes)
    key_w = 10,              -- W key - main thruster (upward)
    key_a = 8,               -- A key - left side thruster
    key_s = 11,              -- S key - down (unused for now)
    key_d = 9,               -- D key - right side thruster

    -- Arrow key mappings (input indices)
    arrow_left = 0,          -- Left arrow (input index 0)
    arrow_right = 1,         -- Right arrow (input index 1)
    arrow_up = 2,            -- Up arrow (input index 2)
    arrow_down = 3,          -- Down arrow (input index 3)

    -- Other controls
    thrust = 4,              -- Z key (button 4) - primary fire
    menu_select = 4,         -- Z key (same as thrust)
    primary_weapon = 5,      -- X key - toggle primary weapon (button 5)
    secondary_weapon = 2,    -- C key - toggle secondary weapon (up button when not moving)

    -- Mouse controls
    mouse_primary = true,    -- Left click for primary weapon
    mouse_secondary = true,  -- Right click for secondary weapon
    mouse_aiming = true,     -- Enable mouse aiming
}

-- =======================
-- WEAPON CONFIGURATION
-- =======================
weapon_config = {
    -- Primary weapons (spread values adjusted for Picotron 0-1 angle system)
    primary_weapons = {
        {name = "Standard", damage = 10, rate = 0.2, bullets = 1, spread = 0, color = 7, cost = 0},     -- White - Free starter
        {name = "Burst Fire", damage = 8, rate = 0.15, bullets = 3, spread = 0.02, color = 10, cost = 150}, -- Yellow
        {name = "Shotgun", damage = 6, rate = 0.4, bullets = 5, spread = 0.08, color = 9, cost = 200},      -- Orange
        {name = "Laser", damage = 15, rate = 0.1, bullets = 1, spread = 0, color = 12, cost = 300},         -- Light blue
        {name = "Heavy Cannon", damage = 25, rate = 0.8, bullets = 1, spread = 0, color = 8, cost = 500}    -- Red
    },
    
    -- Secondary weapons
    secondary_weapons = {
        {name = "None", damage = 0, rate = 0, color = 7, cost = 0},        -- White - Free starter
        {name = "Missiles", damage = 30, rate = 1.0, color = 11, cost = 250}, -- Light green
        {name = "Bombs", damage = 40, rate = 1.5, color = 8, cost = 400}     -- Red
    },
    
    -- Enemy bullet trail
    enemy_bullet_trail = true,
    enemy_bullet_color = 12,  -- Bright blue
    trail_length = 5,
    
    -- Line of sight
    los_enabled = true,      -- Show line of sight
    los_color = 6,           -- Light grey
    los_max_length = 150,    -- Maximum line length
    los_dot_spacing = 8,     -- Pixels between dots
}

-- =======================
-- MONEY CONFIGURATION
-- =======================
money_config = {
    starting_money = 50,     -- Start with some money for initial purchases
    enemy_kill_reward = 10,
    coin_collect_distance = 25,  -- Increased for easier collection
    coin_lifetime = 600,  -- 10 seconds
    coin_colors = {9, 10},  -- Orange, yellow only
    coin_attraction_distance = 80,  -- Distance at which coins start flying to player
    coin_attraction_speed = 2.0,    -- Speed coins move towards player

    -- Shop costs
    refuel_cost_per_unit = 1,    -- Cost per fuel unit (cheap)
    repair_cost_per_unit = .5,    -- Cost per health unit (more expensive)
}

-- =======================
-- GAME BALANCE
-- =======================
balance_config = {
    -- Crash damage
    crash_velocity_threshold = 2, -- Speed that causes crash damage
    crash_damage = 20,
    
    -- Fuel crash mechanics
    fuel_crash_destruction = true,  -- Enable fuel-based destruction
    fuel_crash_velocity_threshold = 1.5,  -- Lower threshold when out of fuel
    
    -- Level progression
    starting_level = 1,
    max_level = 99,          -- Theoretical max (game can go indefinitely)
    
    -- Difficulty scaling
    enemy_health_scale = 1.0,  -- Multiplier for enemy health per level
    enemy_spawn_scale = 0.5,   -- Additional spawn chance per level
    
    -- Scoring (for future implementation)
    points_per_landing = 100,
    points_per_enemy_kill = 50,
    points_per_level = 500,
}

-- =======================
-- AUDIO CONFIGURATION (for future use)
-- =======================
audio_config = {
    -- Sound effects (SFX numbers when available)
    thrust_sound = 1,
    shoot_sound = 0,      -- SFX 0 for ship weapon firing
    enemy_shoot_sound = 8, -- SFX 8 for enemy weapon firing
    explosion_sound = 2,  -- SFX 2 for ship death/explosion
    landing_sound = 3,    -- SFX 3 for successful landing
    coin_pickup_sound = 4, -- SFX 4 for coin collection
    enemy_hit_sound = nil,

    -- Music tracks
    menu_music = nil,
    game_music = nil,
    upgrade_music = nil,

    -- Volume levels (0.0 to 1.0)
    sfx_volume = 0.7,
    music_volume = 0.5,
}