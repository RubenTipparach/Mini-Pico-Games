local game = {
    cheer = 0,           -- Main currency: Holiday Cheer
    toys = 0,            -- Toys in warehouse
    delivered = 0,       -- Total toys delivered
    time = 0,            -- Game time in seconds
    frame = 0,           -- Frame counter
    santa_cheer = 100000, -- Santa's starting cheer (he's ahead!)
    santa_rate = 10,     -- Santa gains cheer per second
    won = false,
    phase = 1,
    tab = 1,             -- Current UI tab (1=Produce, 2=Deliver, 3=Market, 4=Upgrade)
    messages = {},       -- Floating messages
    snowflakes = {},     -- Background snow
}

-- =====================
-- PRODUCTION SYSTEM
-- =====================
local production = {
    -- Manual clicking
    click_power = 1,        -- Toys per click
    click_cooldown = 0,     -- Visual feedback timer

    -- Elves (workers)
    elves = 0,
    elf_cost = 10,          -- HC cost
    elf_rate = 0.5,         -- Toys per second per elf
    elf_mult = 1,           -- Multiplier from upgrades

    -- Toy Factories
    factories = {
        {name="Workshop", count=0, cost=50, rate=2, owned=false},
        {name="Mini Factory", count=0, cost=500, rate=10, owned=false},
        {name="Mega Plant", count=0, cost=5000, rate=50, owned=false},
        {name="Robo-Fab", count=0, cost=50000, rate=300, owned=false},
        {name="Quantum Forge", count=0, cost=500000, rate=2000, owned=false},
    },
    factory_mult = 1,
}

-- =====================
-- DELIVERY SYSTEM
-- =====================
local delivery = {
    -- Manual delivery
    click_power = 1,        -- Toys delivered per click
    click_cooldown = 0,
    cheer_per_toy = 1,      -- Base HC earned per toy delivered

    -- Delivery elves
    elves = 0,
    elf_cost = 20,
    elf_rate = 0.3,         -- Deliveries per second per elf
    elf_mult = 1,

    -- Delivery methods
    methods = {
        {name="Bicycle Squad", count=0, cost=100, rate=2, mult=1, owned=false},
        {name="Van Fleet", count=0, cost=1000, rate=8, mult=1.2, owned=false},
        {name="Drone Network", count=0, cost=10000, rate=30, mult=1.5, owned=false},
        {name="Rocket Express", count=0, cost=100000, rate=150, mult=2, owned=false},
        {name="Teleporter", count=0, cost=1000000, rate=1000, mult=3, owned=false},
    },
    method_mult = 1,
}

-- =====================
-- MARKETING SYSTEM
-- =====================
local marketing = {
    cheer_mult = 1,         -- Global cheer multiplier

    campaigns = {
        {name="Flyers", cost=25, mult=0.1, owned=false, desc="Word of mouth"},
        {name="Local Radio", cost=200, mult=0.2, owned=false, desc="Town knows you"},
        {name="YouTube Ads", cost=1500, mult=0.5, owned=false, desc="Go viral!"},
        {name="TV Spots", cost=10000, mult=1.0, owned=false, desc="Prime time"},
        {name="Celebrity", cost=75000, mult=2.0, owned=false, desc="Star power!"},
        {name="Super Bowl", cost=500000, mult=5.0, owned=false, desc="EVERYONE knows"},
    },

    -- Passive cheer generators
    generators = {
        {name="Gift Shop", count=0, cost=500, rate=1, owned=false},
        {name="Theme Park", count=0, cost=5000, rate=8, owned=false},
        {name="Streaming", count=0, cost=40000, rate=50, owned=false},
        {name="Merch Empire", count=0, cost=300000, rate=400, owned=false},
    },
}

-- =====================
-- UPGRADES SYSTEM
-- =====================
local upgrades = {
    production = {
        {name="Better Tools", cost=100, mult=2, desc="+100% click", owned=false, type="click"},
        {name="Power Tools", cost=1000, mult=2, desc="+100% click", owned=false, type="click"},
        {name="Elf Training", cost=500, mult=2, desc="+100% elf prod", owned=false, type="elf"},
        {name="Elf Masters", cost=5000, mult=2, desc="+100% elf prod", owned=false, type="elf"},
        {name="Automation I", cost=2000, mult=1.5, desc="+50% factories", owned=false, type="factory"},
        {name="Automation II", cost=20000, mult=2, desc="+100% factories", owned=false, type="factory"},
        {name="AI Assembly", cost=200000, mult=3, desc="+200% factories", owned=false, type="factory"},
    },
    delivery = {
        {name="GPS Routes", cost=200, mult=2, desc="+100% del click", owned=false, type="click"},
        {name="Fast Lanes", cost=2000, mult=2, desc="+100% del click", owned=false, type="click"},
        {name="Del. Training", cost=800, mult=2, desc="+100% del elves", owned=false, type="elf"},
        {name="Speed Elves", cost=8000, mult=2, desc="+100% del elves", owned=false, type="elf"},
        {name="Fleet Upgrade", cost=5000, mult=1.5, desc="+50% methods", owned=false, type="method"},
        {name="Turbo Fleet", cost=50000, mult=2, desc="+100% methods", owned=false, type="method"},
    },
    cheer = {
        {name="Jingle Bells", cost=300, mult=1.2, desc="+20% all cheer", owned=false},
        {name="Carol Singers", cost=3000, mult=1.3, desc="+30% all cheer", owned=false},
        {name="Holiday Magic", cost=30000, mult=1.5, desc="+50% all cheer", owned=false},
        {name="Christmas Spirit", cost=300000, mult=2, desc="+100% all cheer", owned=false},
    },
}

-- =====================
-- MILESTONES
-- =====================
local milestones = {
    {cheer=100, msg="First steps!", reached=false},
    {cheer=1000, msg="Getting noticed!", reached=false},
    {cheer=10000, msg="A real competitor!", reached=false},
    {cheer=50000, msg="Santa's worried!", reached=false},
    {cheer=100000, msg="Equal footing!", reached=false},
    {cheer=250000, msg="Taking the lead!", reached=false},
    {cheer=500000, msg="Almost there!", reached=false},
    {cheer=1000000, msg="YOU WON!", reached=false},
}

-- =====================
-- HELPER FUNCTIONS
-- =====================
function format_num(n)
    if n >= 1000000 then
        return string.format("%.1fM", n/1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n/1000)
    else
        return string.format("%.0f", n)
    end
end

function add_message(x, y, text, color)
    table.insert(game.messages, {
        x=x, y=y, text=text, color=color or 11, life=60
    })
end

function lerp(a, b, t)
    return a + (b - a) * t
end

-- =====================
-- PRODUCTION FUNCTIONS
-- =====================
function click_produce()
    local amount = production.click_power
    game.toys = game.toys + amount
    production.click_cooldown = 10
    add_message(60, 50, "+"..amount.." toy", 11)
end

function buy_prod_elf()
    if game.cheer >= production.elf_cost then
        game.cheer = game.cheer - production.elf_cost
        production.elves = production.elves + 1
        production.elf_cost = math.floor(production.elf_cost * 1.15)
        add_message(120, 30, "+1 Elf!", 10)
    end
end

function buy_factory(idx)
    local f = production.factories[idx]
    if game.cheer >= f.cost then
        game.cheer = game.cheer - f.cost
        f.count = f.count + 1
        f.cost = math.floor(f.cost * 1.2)
        f.owned = true
        add_message(120, 40, "+"..f.name, 14)
    end
end

function get_toy_rate()
    local rate = 0
    -- Elves
    rate = rate + production.elves * production.elf_rate * production.elf_mult
    -- Factories
    for _, f in ipairs(production.factories) do
        rate = rate + f.count * f.rate * production.factory_mult
    end
    return rate
end

-- =====================
-- DELIVERY FUNCTIONS
-- =====================
function click_deliver()
    if game.toys >= delivery.click_power then
        local amount = math.min(delivery.click_power, game.toys)
        game.toys = game.toys - amount
        game.delivered = game.delivered + amount
        local cheer_gain = amount * delivery.cheer_per_toy * marketing.cheer_mult
        game.cheer = game.cheer + cheer_gain
        delivery.click_cooldown = 10
        add_message(180, 50, "+"..format_num(cheer_gain).." HC", 12)
    end
end

function buy_del_elf()
    if game.cheer >= delivery.elf_cost then
        game.cheer = game.cheer - delivery.elf_cost
        delivery.elves = delivery.elves + 1
        delivery.elf_cost = math.floor(delivery.elf_cost * 1.15)
        add_message(120, 30, "+1 Delivery Elf!", 9)
    end
end

function buy_method(idx)
    local m = delivery.methods[idx]
    if game.cheer >= m.cost then
        game.cheer = game.cheer - m.cost
        m.count = m.count + 1
        m.cost = math.floor(m.cost * 1.25)
        m.owned = true
        add_message(120, 40, "+"..m.name, 14)
    end
end

function get_delivery_rate()
    local rate = 0
    -- Elves
    rate = rate + delivery.elves * delivery.elf_rate * delivery.elf_mult
    -- Methods
    for _, m in ipairs(delivery.methods) do
        rate = rate + m.count * m.rate * delivery.method_mult
    end
    return rate
end

-- =====================
-- MARKETING FUNCTIONS
-- =====================
function buy_campaign(idx)
    local c = marketing.campaigns[idx]
    if not c.owned and game.cheer >= c.cost then
        game.cheer = game.cheer - c.cost
        c.owned = true
        marketing.cheer_mult = marketing.cheer_mult + c.mult
        add_message(120, 40, c.name.." active!", 12)
    end
end

function buy_generator(idx)
    local g = marketing.generators[idx]
    if game.cheer >= g.cost then
        game.cheer = game.cheer - g.cost
        g.count = g.count + 1
        g.cost = math.floor(g.cost * 1.3)
        g.owned = true
        add_message(120, 40, "+"..g.name, 6)
    end
end

function get_passive_cheer_rate()
    local rate = 0
    for _, g in ipairs(marketing.generators) do
        rate = rate + g.count * g.rate
    end
    return rate * marketing.cheer_mult
end

-- =====================
-- UPGRADE FUNCTIONS
-- =====================
function buy_upgrade(category, idx)
    local u
    if category == "production" then
        u = upgrades.production[idx]
    elseif category == "delivery" then
        u = upgrades.delivery[idx]
    else
        u = upgrades.cheer[idx]
    end

    if not u.owned and game.cheer >= u.cost then
        game.cheer = game.cheer - u.cost
        u.owned = true

        -- Apply upgrade
        if category == "production" then
            if u.type == "click" then
                production.click_power = production.click_power * u.mult
            elseif u.type == "elf" then
                production.elf_mult = production.elf_mult * u.mult
            elseif u.type == "factory" then
                production.factory_mult = production.factory_mult * u.mult
            end
        elseif category == "delivery" then
            if u.type == "click" then
                delivery.click_power = delivery.click_power * u.mult
            elseif u.type == "elf" then
                delivery.elf_mult = delivery.elf_mult * u.mult
            elseif u.type == "method" then
                delivery.method_mult = delivery.method_mult * u.mult
            end
        else
            marketing.cheer_mult = marketing.cheer_mult * u.mult
        end

        add_message(120, 60, u.name.." unlocked!", 11)
    end
end

-- =====================
-- GAME UPDATE
-- =====================
function update_game()
    game.frame = game.frame + 1

    -- Time tracking (60 fps assumed)
    if game.frame % 60 == 0 then
        game.time = game.time + 1
    end

    -- Production tick (every frame, scaled)
    local toy_rate = get_toy_rate() / 60
    game.toys = game.toys + toy_rate

    -- Delivery tick
    local del_rate = get_delivery_rate() / 60
    if game.toys >= del_rate then
        game.toys = game.toys - del_rate
        game.delivered = game.delivered + del_rate
        local cheer_gain = del_rate * delivery.cheer_per_toy * marketing.cheer_mult
        game.cheer = game.cheer + cheer_gain
    end

    -- Passive cheer
    local passive = get_passive_cheer_rate() / 60
    game.cheer = game.cheer + passive

    -- Santa also gains cheer (competition!)
    game.santa_cheer = game.santa_cheer + game.santa_rate / 60
    -- Santa speeds up over time
    if game.frame % 3600 == 0 then -- Every minute
        game.santa_rate = game.santa_rate * 1.1
    end

    -- Check milestones
    for _, m in ipairs(milestones) do
        if not m.reached and game.cheer >= m.cheer then
            m.reached = true
            add_message(120, 68, m.msg, 11)
            if m.cheer == 1000000 then
                game.won = true
            end
        end
    end

    -- Update phase
    if game.cheer >= 500000 then game.phase = 5
    elseif game.cheer >= 100000 then game.phase = 4
    elseif game.cheer >= 10000 then game.phase = 3
    elseif game.cheer >= 500 then game.phase = 2
    end

    -- Update messages
    for i = #game.messages, 1, -1 do
        local m = game.messages[i]
        m.life = m.life - 1
        m.y = m.y - 0.5
        if m.life <= 0 then
            table.remove(game.messages, i)
        end
    end

    -- Cooldowns
    if production.click_cooldown > 0 then
        production.click_cooldown = production.click_cooldown - 1
    end
    if delivery.click_cooldown > 0 then
        delivery.click_cooldown = delivery.click_cooldown - 1
    end

    -- Snowflakes
    if game.frame % 10 == 0 then
        table.insert(game.snowflakes, {
            x = math.random(0, 240),
            y = 0,
            speed = math.random(5, 15) / 10
        })
    end
    for i = #game.snowflakes, 1, -1 do
        local s = game.snowflakes[i]
        s.y = s.y + s.speed
        s.x = s.x + math.sin(game.frame/20 + i) * 0.3
        if s.y > 136 then
            table.remove(game.snowflakes, i)
        end
    end
end

-- =====================
-- INPUT HANDLING
-- =====================
local prev_btn = false
local mx, my, mb, pmb = 0, 0, false, false

function handle_input()
    -- Mouse input only
    mx, my, mb = mouse()

    -- Mouse clicks
    if mb and not pmb then
        -- Tab buttons (top)
        if my < 12 then
            if mx < 60 then game.tab = 1
            elseif mx < 120 then game.tab = 2
            elseif mx < 180 then game.tab = 3
            else game.tab = 4
            end
        else
            handle_tab_click()
        end
    end

    pmb = mb
end

function handle_tab_click()
    local y_offset = 24
    local item_height = 14

    if game.tab == 1 then -- Production
        -- Manual produce button
        if my >= 20 and my < 34 and mx < 100 then
            click_produce()
        end
        -- Buy elf button
        if my >= 36 and my < 50 and mx < 100 then
            buy_prod_elf()
        end
        -- Factory buttons
        for i, f in ipairs(production.factories) do
            local y = 52 + (i-1) * 14
            if my >= y and my < y + 14 then
                buy_factory(i)
            end
        end

    elseif game.tab == 2 then -- Delivery
        -- Manual deliver button
        if my >= 20 and my < 34 and mx < 100 then
            click_deliver()
        end
        -- Buy delivery elf
        if my >= 36 and my < 50 and mx < 100 then
            buy_del_elf()
        end
        -- Delivery methods
        for i, m in ipairs(delivery.methods) do
            local y = 52 + (i-1) * 14
            if my >= y and my < y + 14 then
                buy_method(i)
            end
        end

    elseif game.tab == 3 then -- Marketing
        -- Campaigns
        for i, c in ipairs(marketing.campaigns) do
            local y = 20 + (i-1) * 12
            if my >= y and my < y + 12 and mx < 120 then
                buy_campaign(i)
            end
        end
        -- Generators
        for i, g in ipairs(marketing.generators) do
            local y = 20 + (i-1) * 12
            if my >= y and my < y + 12 and mx >= 120 then
                buy_generator(i)
            end
        end

    elseif game.tab == 4 then -- Upgrades
        local y = 20
        -- Production upgrades
        for i, u in ipairs(upgrades.production) do
            if my >= y and my < y + 10 and mx < 120 then
                buy_upgrade("production", i)
            end
            y = y + 10
        end
        -- Delivery upgrades (right column)
        y = 20
        for i, u in ipairs(upgrades.delivery) do
            if my >= y and my < y + 10 and mx >= 120 then
                buy_upgrade("delivery", i)
            end
            y = y + 10
        end
        -- Cheer upgrades (bottom)
        y = 95
        for i, u in ipairs(upgrades.cheer) do
            if my >= y and my < y + 10 then
                buy_upgrade("cheer", i)
            end
            y = y + 10
        end
    end
end

-- =====================
-- DRAWING
-- =====================
function draw_game()
    cls(0) -- Black background

    -- Draw snow BEHIND everything
    draw_snow_background()

    -- Header bar
    rect(0, 0, 240, 12, 1)

    -- Tab buttons
    local tabs = {"PRODUCE", "DELIVER", "MARKET", "UPGRADE"}
    for i, t in ipairs(tabs) do
        local x = (i-1) * 60
        local col = game.tab == i and 12 or 6
        rect(x, 0, 59, 11, col)
        print(t, x + 8, 2, 0)
    end

    -- Stats bar at bottom
    rectb(0, 126, 240, 10, 6)
    print("HC:"..format_num(game.cheer), 2, 128, 12)
    print("Toys:"..format_num(game.toys), 60, 128, 11)
    print("Santa:"..format_num(game.santa_cheer), 130, 128, 8)
    print(string.format("%d:%02d", math.floor(game.time/60), game.time%60), 210, 128, 6)

    -- Draw current tab
    if game.tab == 1 then
        draw_production()
    elseif game.tab == 2 then
        draw_delivery()
    elseif game.tab == 3 then
        draw_marketing()
    else
        draw_upgrades()
    end

    -- Draw floating messages
    for _, m in ipairs(game.messages) do
        local alpha = m.life / 60
        print(m.text, m.x, m.y, m.color)
    end

    -- Win screen
    if game.won then
        rect(40, 40, 160, 56, 3)
        rectb(40, 40, 160, 56, 11)
        print("CONGRATULATIONS!", 72, 50, 11)
        print("You beat Santa!", 76, 62, 12)
        print("Holiday Cheer: "..format_num(game.cheer), 60, 74, 10)
        print("Time: "..string.format("%d:%02d", math.floor(game.time/60), game.time%60), 88, 86, 14)
    end
end

function draw_production()
    local y = 16

    -- Stats
    print("Toy Rate: "..format_num(get_toy_rate()).."/s", 140, y, 11)
    y = y + 8

    -- Manual produce button
    local btn_col = production.click_cooldown > 0 and 8 or 11
    rect(4, y, 92, 12, btn_col)
    print("MAKE TOY (+"..format_num(production.click_power)..")", 8, y+3, 0)
    y = y + 16

    -- Elf button
    rect(4, y, 92, 12, game.cheer >= production.elf_cost and 10 or 6)
    print("Hire Elf ("..format_num(production.elf_cost)..")", 8, y+3, 0)
    print("Elves: "..production.elves, 100, y+3, 10)
    y = y + 16

    -- Factories
    print("--FACTORIES--", 4, y, 14)
    y = y + 10
    for i, f in ipairs(production.factories) do
        local can_afford = game.cheer >= f.cost
        local col = can_afford and 14 or 6
        rect(4, y, 140, 12, col)
        print(f.name.." x"..f.count, 8, y+3, 0)
        print(format_num(f.cost).." HC", 100, y+3, 0)
        print("+"..format_num(f.rate).."/s", 160, y+3, 11)
        y = y + 14
    end
end

function draw_delivery()
    local y = 16

    -- Stats
    print("Del Rate: "..format_num(get_delivery_rate()).."/s", 130, y, 12)
    print("Cheer x"..string.format("%.1f", marketing.cheer_mult), 130, y+8, 11)
    y = y + 8

    -- Manual deliver button
    local btn_col = delivery.click_cooldown > 0 and 8 or 12
    if game.toys < delivery.click_power then btn_col = 6 end
    rect(4, y, 92, 12, btn_col)
    print("DELIVER (+"..format_num(delivery.click_power)..")", 8, y+3, 0)
    y = y + 16

    -- Delivery elf button
    rect(4, y, 92, 12, game.cheer >= delivery.elf_cost and 9 or 6)
    print("Delivery Elf ("..format_num(delivery.elf_cost)..")", 8, y+3, 0)
    print("D.Elves: "..delivery.elves, 100, y+3, 9)
    y = y + 16

    -- Delivery methods
    print("--METHODS--", 4, y, 14)
    y = y + 10
    for i, m in ipairs(delivery.methods) do
        local can_afford = game.cheer >= m.cost
        local col = can_afford and 9 or 6
        rect(4, y, 140, 12, col)
        print(m.name.." x"..m.count, 8, y+3, 0)
        print(format_num(m.cost).." HC", 100, y+3, 0)
        print("+"..format_num(m.rate).."/s", 160, y+3, 12)
        y = y + 14
    end
end

function draw_marketing()
    -- Campaigns (left side)
    print("CAMPAIGNS", 4, 14, 11)
    local y = 22
    for i, c in ipairs(marketing.campaigns) do
        local col = c.owned and 3 or (game.cheer >= c.cost and 12 or 6)
        rect(4, y, 110, 10, col)
        local status = c.owned and "[OK]" or format_num(c.cost)
        print(c.name..": "..status, 6, y+2, 0)
        y = y + 12
    end

    -- Generators (right side)
    print("GENERATORS", 124, 14, 11)
    y = 22
    for i, g in ipairs(marketing.generators) do
        local col = game.cheer >= g.cost and 6 or 1
        if g.count > 0 then col = 5 end
        rect(124, y, 110, 10, col)
        print(g.name.." x"..g.count, 126, y+2, 11)
        print(format_num(g.cost), 200, y+2, 12)
        y = y + 12
    end

    -- Passive cheer rate
    print("Passive HC: +"..format_num(get_passive_cheer_rate()).."/s", 4, 100, 12)
    print("Cheer Mult: x"..string.format("%.1f", marketing.cheer_mult), 4, 110, 11)
end

function draw_upgrades()
    -- Production upgrades (left)
    print("PRODUCTION", 4, 14, 11)
    local y = 22
    for i, u in ipairs(upgrades.production) do
        local col = u.owned and 3 or (game.cheer >= u.cost and 11 or 1)
        print(u.name, 6, y, col)
        if not u.owned then
            print(format_num(u.cost), 60, y, 12)
        else
            print("[OK]", 60, y, 3)
        end
        y = y + 10
    end

    -- Delivery upgrades (right)
    print("DELIVERY", 124, 14, 12)
    y = 22
    for i, u in ipairs(upgrades.delivery) do
        local col = u.owned and 3 or (game.cheer >= u.cost and 12 or 1)
        print(u.name, 126, y, col)
        if not u.owned then
            print(format_num(u.cost), 180, y, 12)
        else
            print("[OK]", 180, y, 3)
        end
        y = y + 10
    end

    -- Cheer upgrades (bottom)
    print("CHEER BOOSTS", 4, 88, 14)
    y = 98
    for i, u in ipairs(upgrades.cheer) do
        local col = u.owned and 3 or (game.cheer >= u.cost and 14 or 1)
        print(u.name..": "..u.desc, 6, y, col)
        if not u.owned then
            print(format_num(u.cost), 160, y, 12)
        else
            print("[OK]", 160, y, 3)
        end
        y = y + 10
    end
end

-- =====================
-- MAIN LOOP
-- =====================
function TIC()
    if not game.won then
        handle_input()
        update_game()
    end
    draw_game()
end

-- =====================
-- SPRITE CONSTANTS
-- =====================
-- SPRITE DATA & INITIALIZATION
-- =====================
-- TIC-80 sprite memory starts at 0x4000
-- Each sprite is 32 bytes (8x8 pixels, 4 bits per pixel)

-- Sprite data as hex strings (each char = 1 pixel, 0-f = palette color)
local SPRITE_DATA = {
    -- 001: Production Elf (green hat, white face, green body)
    [1] = "0006600000666600006cc60000cccc0006666660066006600060060000600600",
    -- 002: Delivery Elf (blue variant)
    [2] = "0009900000999900009cc90000cccc0009999990099009900090090000900900",
    -- 003: Santa (red suit, white beard, black boots)
    [3] = "00ccc000002c2000002cc20000cccc0002cccc20022222200020020000f00f00",
    -- 004: Teddy Bear (orange fur, button eyes)
    [4] = "0330033003333330333003333333333303333330333333330330033003300330",
    -- 005: Robot (gray body, blue eyes)
    [5] = "00dddd000da99ad00ddddddd0dddddd00d9dd9d00ddddddd00d00d0000d00d00",
    -- 006: Toy Train (green engine, wheels)
    [6] = "000000000066666006f66f6006666660066666600060060006666660000ff000",
    -- 007: Doll (orange hair, red dress)
    [7] = "00033000003cc30003cccc300c3cc3c003cccc3000333300003003000f300f30",
    -- 008: Gift Box (yellow bow, red wrap)
    [8] = "0004400000444400044224402222422222242222222422220222222000000000",
    -- 009: Bicycle
    [9] = "0000f0000000ff00000ffff00ff0f0ff0ffffff000ffff0000f00f00f000000f",
    -- 010: Van (gray body)
    [10] = "00eeee000eeeeee0eeeeeeeeee9ee9eeeeeeeeee0eeeeee000eeee0000e00e00",
    -- 011: Drone (cyan, propellers)
    [11] = "000bb0000bbbbbb0bb0bb0bbbbb99bbbbbbbbbbbb0bbbb0b0b0bb0b000b00b00",
    -- 012: Rocket (yellow body, flames)
    [12] = "00044000004444000444444044449444044444400444444004040400003ee300",
    -- 013: Teleporter (cyan swirl)
    [13] = "0b0bb0b0bbbbbbbbbbbbbbbbbb0bb0bb0bbbbbb00b0bb0b000bbbb0000b00b00",
    -- 014: Star (yellow sparkle)
    [14] = "00044000004444000444444004ffff40044ff44004ffff400044440000044000",
    -- 015: Christmas Tree (green with ornaments)
    [15] = "00066000006666000665566065666656666666666566665600666600006006",
    -- 048: Snowflake
    [48] = "000c000000ccc0000c0c0c00000c0000000c00000c0c0c0000ccc000000c0000",
    -- 049: Heart
    [49] = "00000000066006600666666006666660006666000006600000000000000000",
    -- 050: Coin
    [50] = "00044000004f4400044ff44004ffff4004ffff400444444000044000000440",
    -- 051: Megaphone
    [51] = "000ee0000eeeeee0eec00cee0eeeeee00eeeeee00ee00ee00e0000e000e00e00",
    -- 052: TV
    [52] = "00eeee000e0ee0e00eeeeee00e0ee0e000eeee00000ee0000000000000000000",
    -- 053: Phone
    [53] = "00099000009999000999999009a99a9009999990009999000009900000099000",
}

-- Convert hex char to number
function hex_to_num(c)
    local n = string.byte(c)
    if n >= 48 and n <= 57 then return n - 48 end      -- 0-9
    if n >= 97 and n <= 102 then return n - 87 end     -- a-f
    if n >= 65 and n <= 70 then return n - 55 end      -- A-F
    return 0
end

-- Initialize sprites by poking data into VRAM
function init_sprites()
    for sprite_id, hex_data in pairs(SPRITE_DATA) do
        local base_addr = 0x4000 + (sprite_id * 32)
        for row = 0, 7 do
            for col = 0, 3 do
                local idx = row * 8 + col * 2 + 1
                local hi = hex_to_num(hex_data:sub(idx, idx))
                local lo = hex_to_num(hex_data:sub(idx + 1, idx + 1))
                -- TIC-80 stores 2 pixels per byte, low nibble first
                local byte_val = lo * 16 + hi
                poke(base_addr + row * 4 + col, byte_val)
            end
        end
    end
end

-- Initialize sprites on load
init_sprites()

-- =====================
-- SPRITE CONSTANTS
-- =====================
SPR = {
    -- Characters (8x8)
    ELF_PROD = 1,
    ELF_DEL = 2,
    SANTA = 3,

    -- Toys (8x8)
    TEDDY = 4,
    ROBOT = 5,
    TRAIN = 6,
    DOLL = 7,
    GIFT = 8,

    -- Vehicles (8x8)
    BICYCLE = 9,
    VAN = 10,
    DRONE = 11,
    ROCKET = 12,
    TELEPORT = 13,

    -- Icons (8x8)
    STAR = 14,
    TREE = 15,
    SNOWFLAKE = 48,
    HEART = 49,
    COIN = 50,

    -- Marketing (8x8)
    MEGAPHONE = 51,
    TV = 52,
    PHONE = 53,
}

-- =====================
-- ANIMATED SPRITE HELPER
-- =====================
function draw_sprite(id, x, y, scale, flip, frame)
    scale = scale or 1
    flip = flip or 0
    frame = frame or 0
    spr(id + frame, x, y, 0, scale, flip)
end

-- Draw 16x16 sprite (2x2 tiles)
function draw_big_sprite(id, x, y, scale)
    scale = scale or 1
    spr(id, x, y, 0, scale)
    spr(id+1, x+8*scale, y, 0, scale)
    spr(id+16, x, y+8*scale, 0, scale)
    spr(id+17, x+8*scale, y+8*scale, 0, scale)
end

-- =====================
-- ENHANCED DRAWING WITH SPRITES
-- =====================
function draw_animated_elf(x, y, type, frame)
    local id = type == "prod" and SPR.ELF_PROD or SPR.ELF_DEL
    local f = math.floor(frame / 15) % 2
    spr(id, x, y, 0, 1, f)
end

function draw_animated_santa(x, y, frame)
    local f = math.floor(frame / 30) % 2
    spr(SPR.SANTA, x, y, 0, 1, f)
end

function draw_toy(x, y, type)
    local toys = {SPR.TEDDY, SPR.ROBOT, SPR.TRAIN, SPR.DOLL, SPR.GIFT}
    spr(toys[(type % 5) + 1], x, y)
end

-- =====================
-- UPDATED DRAW FUNCTIONS WITH SPRITES
-- =====================
function draw_production_sprites()
    -- Draw elves working
    for i = 1, math.min(production.elves, 8) do
        local x = 180 + ((i-1) % 4) * 12
        local y = 16 + math.floor((i-1) / 4) * 14
        draw_animated_elf(x, y, "prod", game.frame + i * 7)
    end

    -- Draw factory icons
    local factory_sprites = {SPR.WORKSHOP, SPR.FACTORY, SPR.MEGAPLANT, SPR.ROBOT, SPR.ROCKET}
    for i, f in ipairs(production.factories) do
        if f.count > 0 then
            local y = 52 + (i-1) * 14
            spr(factory_sprites[i] or SPR.GIFT, 148, y + 2)
        end
    end

    -- Floating toys when producing
    if production.click_cooldown > 5 then
        spr(SPR.TEDDY, 98, 22 - (10 - production.click_cooldown))
    end
end

function draw_delivery_sprites()
    -- Draw delivery elves
    for i = 1, math.min(delivery.elves, 8) do
        local x = 180 + ((i-1) % 4) * 12
        local y = 16 + math.floor((i-1) / 4) * 14
        draw_animated_elf(x, y, "del", game.frame + i * 5)
    end

    -- Draw vehicle icons
    local vehicle_sprites = {SPR.BICYCLE, SPR.VAN, SPR.DRONE, SPR.ROCKET, SPR.TELEPORT}
    for i, m in ipairs(delivery.methods) do
        if m.count > 0 then
            local y = 52 + (i-1) * 14
            local wobble = math.sin(game.frame/10 + i) * 1
            spr(vehicle_sprites[i], 148, y + 2 + wobble)
        end
    end

    -- Gift flying when delivering
    if delivery.click_cooldown > 5 then
        spr(SPR.GIFT, 98, 22 - (10 - delivery.click_cooldown))
    end
end

function draw_marketing_sprites()
    -- Draw campaign icons
    local camp_sprites = {SPR.MEGAPHONE, SPR.MEGAPHONE, SPR.TV, SPR.TV, SPR.STAR, SPR.STAR}
    for i, c in ipairs(marketing.campaigns) do
        if c.owned then
            spr(camp_sprites[i], 100, 22 + (i-1) * 12)
        end
    end

    -- Draw generator icons
    local gen_sprites = {SPR.GIFT, SPR.TREE, SPR.TV, SPR.STAR}
    for i, g in ipairs(marketing.generators) do
        if g.count > 0 then
            spr(gen_sprites[i], 220, 22 + (i-1) * 12)
        end
    end
end

function draw_santa_competitor()
    -- Draw Santa in corner with animation
    local bounce = math.sin(game.frame / 20) * 2
    spr(SPR.SANTA, 224, 115 + bounce)

    -- Competition bar
    local player_pct = game.cheer / (game.cheer + game.santa_cheer)
    local bar_w = 50
    rect(170, 118, bar_w, 4, 8)
    rect(170, 118, math.floor(bar_w * player_pct), 4, 6)
    pix(170 + math.floor(bar_w * 0.5), 117, 4) -- Midpoint marker
end

function draw_header_icons()
    -- Star icon for cheer in status bar
    spr(SPR.STAR, 52, 127)
    -- Gift icon for toys
    spr(SPR.GIFT, 112, 127)
end

function draw_decorations()
    -- Christmas trees in corners (drawn in UI layer)
    if game.phase >= 2 then
        spr(SPR.TREE, 232, 14)
    end
    if game.phase >= 3 then
        spr(SPR.TREE, 0, 115)
    end
end

-- Draw snow BEFORE UI (called early in draw_game)
function draw_snow_background()
    -- Pixel snowflakes
    for _, s in ipairs(game.snowflakes) do
        pix(s.x, s.y, 12)
    end
    -- Sprite snowflakes (every 5th one, larger flakes)
    for i, s in ipairs(game.snowflakes) do
        if i % 5 == 0 and s.y < 120 then
            spr(SPR.SNOWFLAKE, s.x, s.y)
        end
    end
end

-- =====================
-- MAIN LOOP
-- =====================
function TIC()
    if not game.won then
        handle_input()
        update_game()
    end
    draw_game()

    -- Draw sprites on top
    if game.tab == 1 then
        draw_production_sprites()
    elseif game.tab == 2 then
        draw_delivery_sprites()
    elseif game.tab == 3 then
        draw_marketing_sprites()
    end

    draw_santa_competitor()
    draw_header_icons()
    draw_decorations()
end
