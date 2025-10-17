-- waves.lua - enemy wave spawning and progression

waves = {
    current_wave = 1,
    spawn_timer = 0,
    enemies_this_wave = 0,
    enemies_spawned = 0,
    wave_complete = false,
    difficulty_mult = 1
}

function waves.init()
    waves.reset()
end

function waves.reset()
    waves.current_wave = 1
    waves.spawn_timer = 0
    waves.enemies_this_wave = 3
    waves.enemies_spawned = 0
    waves.wave_complete = false
    waves.difficulty_mult = 1
end

function waves.update()
    waves.spawn_timer -= 1
    
    -- calculate density based on player level
    local level_density_mult = 1 + (xp.level - 1) * 0.3 -- 30% more density per level
    local target_enemy_count = flr(8 * level_density_mult) -- base 8 enemies, scales with level
    
    -- spawn enemies for current wave
    if waves.enemies_spawned < waves.enemies_this_wave and waves.spawn_timer <= 0 then
        waves.spawn_enemy()
        waves.enemies_spawned += 1
        waves.spawn_timer = 60 + rnd(120) -- 1-3 seconds between spawns
    end
    
    -- check if wave is complete
    if waves.enemies_spawned >= waves.enemies_this_wave and #enemies.get_list() == 0 then
        if not waves.wave_complete then
            waves.wave_complete = true
            waves.next_wave()
        end
    end
    
    -- continuous spawning after wave 5 with level-based density
    if waves.current_wave >= 5 then
        local current_enemy_count = #enemies.get_list()
        if current_enemy_count < target_enemy_count and waves.spawn_timer <= 0 then
            waves.spawn_enemy()
            -- faster spawning over time and with level
            local base_spawn_time = max(30, 180 - waves.current_wave * 5)
            waves.spawn_timer = max(15, flr(base_spawn_time / level_density_mult))
        end
    end
    
    -- also maintain asteroid density based on level
    local target_asteroid_count = flr(12 * (1 + (xp.level - 1) * 0.2)) -- 20% more asteroids per level
    if #asteroids.get_list() < target_asteroid_count and rnd(200) < 1 then
        asteroids.spawn()
    end
end

function waves.spawn_enemy()
    local x, y = waves.get_spawn_position()
    
    -- choose enemy type based on wave
    local enemy_type = "scout"
    
    if waves.current_wave >= 3 then
        local r = rnd(1)
        if r < 0.6 then
            enemy_type = "scout"
        elseif r < 0.85 then
            enemy_type = "fighter" 
        else
            enemy_type = "bomber"
        end
    elseif waves.current_wave >= 2 then
        enemy_type = rnd(1) < 0.7 and "scout" or "fighter"
    end
    
    enemies.spawn(enemy_type, x, y)
end

function waves.get_spawn_position()
    -- use the enemy spawning system instead of duplicating logic
    return enemies.get_spawn_position()
end

function waves.next_wave()
    waves.current_wave += 1
    waves.enemies_spawned = 0
    waves.wave_complete = false
    waves.difficulty_mult += 0.1
    
    -- increase enemies per wave
    if waves.current_wave <= 5 then
        waves.enemies_this_wave = 2 + waves.current_wave * 2
    else
        -- continuous spawning mode
        waves.enemies_this_wave = 999
    end
    
    -- reset spawn timer for immediate spawn
    waves.spawn_timer = 30
end

function waves.get_wave_info()
    return {
        wave = waves.current_wave,
        enemies_left = max(0, waves.enemies_this_wave - waves.enemies_spawned),
        is_endless = waves.current_wave >= 5
    }
end