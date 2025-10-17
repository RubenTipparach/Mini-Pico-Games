-- LANDER'S REVENGE - Simple Dialog System

-- Dialog state
dialog_active = false
dialog_text = ""
dialog_image = "[PLACEHOLDER]"

-- Simple story sequence
story_texts = {
    "Welcome to LANDER'S REVENGE! You are Tom Lander, bastard son of King Fexril.",
    "Your father has died. It's time to reclaim your rightful throne!",
    "Navigate from the dark side of the moon to Armstrong City.",
    "Press Z to start your journey!"
}

current_story = 1

function start_simple_dialog()
    if debug_mode then print("Starting simple dialog") end
    dialog_active = true
    dialog_text = story_texts[current_story] or "No more story."
    dialog_image = "[PLACEHOLDER " .. current_story .. "]"
end

function update_dialog()
    if debug_mode then print("Updating dialog, active=" .. tostr(dialog_active)) end
    
    -- Check for any button press to advance
    local any_button = false
    for i = 0, 5 do
        if btnp(i) then
            any_button = true
            if debug_mode then print("Button " .. i .. " pressed!") end
            break
        end
    end
    
    if any_button and dialog_active then
        if debug_mode then print("Advancing dialog from " .. current_story) end
        current_story += 1
        
        if current_story <= #story_texts then
            -- Show next story
            dialog_text = story_texts[current_story]
            dialog_image = "[PLACEHOLDER " .. current_story .. "]"
            if debug_mode then print("Showing story " .. current_story) end
        else
            -- End dialog, go to game
            dialog_active = false
            game_state = "playing"
            if debug_mode then print("Dialog complete, going to playing") end
        end
    end
end

function draw_dialog()
    if debug_mode then print("Drawing dialog, active=" .. tostr(dialog_active)) end

    if dialog_active then
        -- Clear screen first
        cls(0)

        -- Draw sprite 16 (intro image) centered in top half of screen
        -- Calculate center position for 128x128 sprite
        local sprite_size = 128
        local sprite_x = (480 / 2) - (sprite_size / 2)  -- Center horizontally on screen
        local sprite_y = 30  -- Position in upper area

        -- Draw border around the sprite (slightly larger than sprite)
        local border_padding = 4
        rect(sprite_x - border_padding, sprite_y - border_padding,
             sprite_x + sprite_size + border_padding, sprite_y + sprite_size + border_padding, 7)

        -- Draw the intro sprite (sprite index 16) - 128x128 pixels (16x16 sprites)
        spr(16, sprite_x, sprite_y, false, false)

        -- Dialog text (bottom half of screen)
        local text_x, text_y = 20, 200
        local text_w, text_h = 440, 120

        -- Text background
        rectfill(text_x, text_y, text_x + text_w, text_y + text_h, 1)
        rect(text_x, text_y, text_x + text_w, text_y + text_h, 7)

        -- Dialog text (wrap text manually for now)
        print(dialog_text, text_x + 10, text_y + 10, 7)

        -- Continue prompt
        print("Press ANY BUTTON to continue", text_x + 10, text_y + text_h - 20, 12)

        if debug_mode then print("Dialog drawn successfully") end
    end
end

function reset_dialog()
    dialog_active = false
    current_story = 1
end