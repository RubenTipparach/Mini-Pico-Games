-- =============================================
-- BAR CHAOS: The Incremental Tavern Simulator
-- A TIC-80 game where your bar gets out of hand!
-- =============================================

local game = {
    state = "splash",
    money = 0,              -- Main currency: $$$
    reputation = 0,         -- Affects customer flow
    customers_served = 0,   -- Total customers served
    chaos_level = 0,        -- How out of hand things are (0-100)
    frame = 0,
    time = 0,
    tab = 1,                -- 1=Drinks, 2=Staff, 3=Promos, 4=Upgrades
    messages = {},
    scroll = {0, 0, 0, 0},
    particles = {},         -- For drink effects
}

-- =====================
-- SWEETIE 16 PALETTE
-- =====================
local C = {
    BLACK = 0, PURPLE = 1, RED = 2, ORANGE = 3,
    YELLOW = 4, LIME = 5, GREEN = 6, TEAL = 7,
    NAVY = 8, BLUE = 9, SKY = 10, CYAN = 11,
    WHITE = 12, SILVER = 13, GRAY = 14, DARK = 15,
}

-- UI Layout
local UI_TOP = 14
local UI_BOTTOM = 118
local UI_HEIGHT = UI_BOTTOM - UI_TOP

-- =====================
-- DRINK RECIPES (The silly ones!)
-- =====================
local drinks = {
    -- Tier 1: Normal-ish
    {name="Boring Beer", price=5, cost=1, time=1.0, unlocked=true,
     desc="Just... beer", chaos=0, icon=1},
    {name="House Wine", price=8, cost=2, time=1.2, unlocked=true,
     desc="Boxed finest", chaos=0, icon=2},

    -- Tier 2: Getting weird
    {name="Flaming Pickle", price=15, cost=5, time=1.5, unlocked=false, unlock_cost=50,
     desc="Literally on fire", chaos=2, icon=3},
    {name="Glitter Bomb", price=20, cost=6, time=1.8, unlocked=false, unlock_cost=100,
     desc="Sparkles forever", chaos=3, icon=4},
    {name="Bacon Martini", price=25, cost=8, time=2.0, unlocked=false, unlock_cost=200,
     desc="Breakfast cocktail", chaos=2, icon=5},

    -- Tier 3: Chaos drinks
    {name="Mystery Meat Shot", price=40, cost=12, time=2.5, unlocked=false, unlock_cost=500,
     desc="Don't ask", chaos=5, icon=6},
    {name="The Screamer", price=60, cost=18, time=3.0, unlocked=false, unlock_cost=1000,
     desc="Makes you yell", chaos=8, icon=7},
    {name="Liquid Regret", price=80, cost=25, time=3.5, unlocked=false, unlock_cost=2000,
     desc="Tastes like Monday", chaos=10, icon=8},

    -- Tier 4: Total madness
    {name="Volcano Surprise", price=120, cost=35, time=4.0, unlocked=false, unlock_cost=5000,
     desc="Actual eruption", chaos=15, icon=9},
    {name="The Existential", price=200, cost=50, time=5.0, unlocked=false, unlock_cost=10000,
     desc="Question reality", chaos=20, icon=10},
    {name="CHAOS JUICE", price=500, cost=100, time=8.0, unlocked=false, unlock_cost=50000,
     desc="Pure madness", chaos=50, icon=11},
}

-- =====================
-- STAFF SYSTEM
-- =====================
local staff = {
    bartenders = 1,         -- Manual serve speed
    bartender_cost = 50,
    bartender_speed = 1.0,  -- Multiplier

    waiters = 0,            -- Auto-serve basic drinks
    waiter_cost = 100,
    waiter_rate = 0.3,      -- Drinks per second

    bouncers = 0,           -- Reduce chaos
    bouncer_cost = 200,
    bouncer_effect = 5,     -- Chaos reduction per bouncer

    djs = 0,                -- Increase customer flow
    dj_cost = 500,
    dj_effect = 1.2,        -- Customer multiplier

    -- Animated staff for background
    staff_anims = {},
}

-- =====================
-- PROMOTIONS (Attract chaos!)
-- =====================
local promos = {
    {name="Happy Hour", cost=25, duration=60, effect=1.5, active=false, timer=0,
     desc="2x customers!", chaos_mult=1.2},
    {name="Karaoke Night", cost=100, duration=90, effect=2.0, active=false, timer=0,
     desc="Singers arrive", chaos_mult=1.5},
    {name="All You Can Drink", cost=300, duration=120, effect=3.0, active=false, timer=0,
     desc="Utter madness", chaos_mult=2.0},
    {name="Celebrity Visit", cost=1000, duration=60, effect=5.0, active=false, timer=0,
     desc="Famous person?!", chaos_mult=1.8},
    {name="Free Samples", cost=50, duration=45, effect=1.3, active=false, timer=0,
     desc="Try everything!", chaos_mult=1.3},
    {name="Costume Party", cost=500, duration=180, effect=2.5, active=false, timer=0,
     desc="Weird outfits", chaos_mult=2.5},
    {name="Speed Drinking", cost=800, duration=60, effect=4.0, active=false, timer=0,
     desc="Competitive!", chaos_mult=3.0},
    {name="Mystery Night", cost=2000, duration=120, effect=6.0, active=false, timer=0,
     desc="What happens?", chaos_mult=4.0},
}

-- =====================
-- UPGRADES
-- =====================
local upgrades = {
    bar = {
        {name="Bigger Bar", cost=100, mult=1.2, desc="+20% capacity", owned=false},
        {name="Neon Signs", cost=300, mult=1.3, desc="+30% tips", owned=false},
        {name="VIP Section", cost=1000, mult=1.5, desc="Rich customers", owned=false},
        {name="Dance Floor", cost=2500, mult=1.8, desc="Party time!", owned=false},
        {name="Rooftop Deck", cost=10000, mult=2.5, desc="Scenic views", owned=false},
    },
    drinks = {
        {name="Better Ice", cost=50, mult=1.1, desc="Colder drinks", owned=false},
        {name="Fancy Glasses", cost=150, mult=1.2, desc="Instagram-able", owned=false},
        {name="Secret Menu", cost=500, mult=1.4, desc="Exclusive vibes", owned=false},
        {name="Mixology 101", cost=1500, mult=1.6, desc="Fancier drinks", owned=false},
        {name="Molecular Bar", cost=8000, mult=2.0, desc="Science drinks!", owned=false},
    },
    chaos = {
        {name="Fire Insurance", cost=200, mult=0.9, desc="-10% chaos", owned=false},
        {name="Cleanup Crew", cost=600, mult=0.8, desc="-20% chaos", owned=false},
        {name="Soundproofing", cost=1200, mult=0.7, desc="Neighbors happy", owned=false},
        {name="Lawyer Retainer", cost=5000, mult=0.5, desc="Legal backup", owned=false},
    },
}

-- Upgrade multipliers
local tip_mult = 1.0
local drink_mult = 1.0
local chaos_reduction = 1.0

-- =====================
-- CUSTOMERS
-- =====================
local customers = {}
local max_customers = 5
local customer_spawn_timer = 0
local base_spawn_rate = 3.0  -- seconds between spawns

local customer_types = {
    {name="Regular", patience=10, tip_mult=1.0, sprite=32, chaos=0},
    {name="Tourist", patience=15, tip_mult=1.5, sprite=33, chaos=1},
    {name="Hipster", patience=8, tip_mult=1.2, sprite=34, chaos=2},
    {name="Bachelor", patience=5, tip_mult=2.0, sprite=35, chaos=5},
    {name="Alien", patience=20, tip_mult=3.0, sprite=36, chaos=10},
    {name="Robot", patience=30, tip_mult=2.5, sprite=37, chaos=3},
    {name="Ghost", patience=60, tip_mult=4.0, sprite=38, chaos=8},
    {name="Dragon", patience=3, tip_mult=10.0, sprite=39, chaos=25},
    {name="Vampire", patience=12, tip_mult=2.0, sprite=40, chaos=7},
    {name="Wizard", patience=25, tip_mult=5.0, sprite=41, chaos=15},
    {name="Pirate", patience=6, tip_mult=3.0, sprite=42, chaos=12},
    {name="Clown", patience=4, tip_mult=1.5, sprite=43, chaos=20},
}

-- Bartender state
local bartender = {
    x = 180,
    y = 60,
    state = "idle",  -- idle, shaking, pouring, serving
    progress = 0,
    current_drink = nil,
    target_customer = nil,
    anim_frame = 0,
}

-- =====================
-- HELPER FUNCTIONS
-- =====================
function format_money(n)
    if n >= 1000000 then
        return string.format("$%.1fM", n/1000000)
    elseif n >= 1000 then
        return string.format("$%.1fK", n/1000)
    else
        return string.format("$%.0f", n)
    end
end

function add_message(x, y, text, color)
    table.insert(game.messages, {
        x=x, y=y, text=text, color=color or C.WHITE, life=60
    })
end

function add_particle(x, y, color, vx, vy)
    table.insert(game.particles, {
        x=x, y=y, color=color, vx=vx or 0, vy=vy or -1, life=30
    })
end

-- =====================
-- SPRITE DATA (Detailed 8x8 pixel art)
-- =====================
local SPRITE_DATA = {
    -- ============ DRINKS (1-16) ============
    -- 001: Beer mug - golden amber with foam head and handle
    [1] = "00444400044cc44004cccc4004ffff4004ffff4004444440043333400043340",
    -- 002: Wine glass - elegant red wine with thin stem
    [2] = "00022000002222000222222002222220002222000001100000011000001111",
    -- 003: Flaming Pickle - green pickle drink with orange flames
    [3] = "03030300363636303656563036565630036666300366663003666630003330",
    -- 004: Glitter Bomb - sparkly pink with floating glitter
    [4] = "0c0b0c00bbbbbb00b2b2b200bb2bb2b00b2bb2b00bbbbbb00bbbbbb0000bb00",
    -- 005: Bacon Martini - pink martini with crispy bacon strip
    [5] = "33200000022222000222222002222220023332200022220000022000000220",
    -- 006: Mystery Meat Shot - suspicious brown chunky drink
    [6] = "0003300003f3f300333333003f33f3f03f3ff3f0033333000033330000033000",
    -- 007: Screamer - bright yellow with visible sound waves
    [7] = "c40c04c04c444c404444444044444440c4c4c4c0c444444c044444400044400",
    -- 008: Liquid Regret - deep blue with tear drops
    [8] = "090c090009999900c99999c009c9c990099c99900999999009090900000990",
    -- 009: Volcano Surprise - red/orange erupting with lava
    [9] = "03230320322323202233322023233232333223333332233303333330003330",
    -- 010: Existential - swirling purple void vortex
    [10] = "0101010011c1c11010c0c0c01c0c0c0c0c0c0c01010c0c01111c111000c1c00",
    -- 011: CHAOS JUICE - rainbow layered madness drink
    [11] = "0b0b0b0002394b00239943b09934b3009222b00092220002239400b0002300",

    -- ============ CUSTOMERS (32-47) ============
    -- 032: Regular Joe - simple happy bar patron
    [32] = "00044000004444000411140004f44f40004444000334433003400430f4004f",
    -- 033: Tourist - Hawaiian shirt, camera around neck
    [33] = "00066000006666000611160006f66f6000666600063636300640046006400640",
    -- 034: Hipster - thick glasses, ironic beard
    [34] = "000330000033330009393900033f3f3003333330033333000330033003300330",
    -- 035: Bachelor Party Guy - party hat, drink in hand
    [35] = "00020000022220002444420024144240244444200443344004300340043003",
    -- 036: Alien - green skin, huge dark eyes
    [36] = "00555000555555005511550055555500555555000555550005500550550055",
    -- 037: Robot - shiny metal, glowing eyes
    [37] = "0dddddd00d9ad9d00ddddddd0d7dd7d00ddddddd00ddddd000d00d0001d01d0",
    -- 038: Ghost - translucent white, floating
    [38] = "00ccc000cccccc00c1cc1c00cccccc00cccccc00ccccccc0c0c0c0c00c0c0c0",
    -- 039: Dragon - red scales, tiny wings, breathing smoke
    [39] = "20232020222222202211220022222220222222202202202022300322207702",
    -- 040: Vampire - pale, red cape, fangs
    [40] = "00022000002222000211120002f22f20002cc200220222220200002002000020",
    -- 041: Wizard - pointy hat, staff
    [41] = "00010000011110001111110011f1f1100111111000111100010010100100101",
    -- 042: Pirate - eyepatch, bandana
    [42] = "0002200000222200021f120002222220024444200022220000200200002002",
    -- 043: Clown - rainbow hair, red nose
    [43] = "023940000239940003f2f30003222300032222300233332003300330033003",

    -- ============ BARTENDER (48-55) ============
    -- 048: Bartender idle - apron, bowtie, friendly face
    [48] = "00099000099999009414149009c22c9009444490099ff990090f0f900909090",
    -- 049: Bartender shaking - arms up shaking cocktail
    [49] = "d0990d00d99999d09414149009c22c900944449009999900090f0f900909090",
    -- 050: Bartender pouring - tilted bottle
    [50] = "00099440099999909414149009c22c9009444490099ff99009000f900909090",
    -- 051: Bartender serving - arm extended with drink
    [51] = "0009900009999900941414900942290009444444099ff99009000f900909090",
    -- 052: Bartender cleaning - wiping glass
    [52] = "00099000099999909414149d09c22c9d094444900d9ff99009000f900909090",

    -- ============ BAR ELEMENTS (56-63) ============
    -- 056: Bar counter top - polished wood grain
    [56] = "3333333333f3f3f336666663366f666336666f633666666333f3f3f3ffffffff",
    -- 057: Bar stool - red cushion, metal frame
    [57] = "00000000002222000222222002222220002222000020020000e00e0000e00e00",
    -- 058: Bottle shelf - wood with bottles
    [58] = "333333333f3f3f3f3f3f3f3f3f3f3f3f333333333223322332233223ffffffff",
    -- 059: Neon OPEN sign - glowing
    [59] = "bbbbbbb0b00000b0b0bbb0b0b0b0b0b0b0bbb0b0b00000b0bbbbbbb000000000",
    -- 060: Music notes - floating
    [60] = "00b0000000bb000b0bbb0bb000bbbb0b0000bbb00000bb0b000b0bb0000000b0",
    -- 061: Dollar sign - golden
    [61] = "00440000044444004404440044444400044044004444440000440000000000",
    -- 062: Tip jar - glass with coins
    [62] = "00000000dddddd00d44454d0d45444d0d44454d0d44444d0dddddd0000000",
    -- 063: Clock - showing late hour
    [63] = "00ddd0000ddddd00dd1d1dd0ddd14dd0dddd1dd00ddddd0000ddd00000000",

    -- ============ EFFECTS (64-71) ============
    -- 064: Fire effect frame 1
    [64] = "00030000003230000323230032323230333333303333333003333300003330",
    -- 065: Fire effect frame 2
    [65] = "00300000032030003232030323232303333333303333333003333300003330",
    -- 066: Sparkle frame 1
    [66] = "000b000000bbb0000bbbbb00bbbbbbb00bbbbb0000bbb00000b0000000b000",
    -- 067: Sparkle frame 2
    [67] = "00000000000b00000b0b0b00000b00000b0b0b00000b000000000000000000",
    -- 068: Heart
    [68] = "022002200222222002222220022222200022220000022000000200000000000",
    -- 069: Star
    [69] = "00040000004440000444440044444440044444400044440000040000000000",
    -- 070: Chaos warning
    [70] = "0022220002222220024224200242242002422420022222200022220000000000",
    -- 071: Broken glass
    [71] = "d000d000dd0d0dd00d0d0d0d00ddd00000d0d0000d000d00d00000d000000000",
}

function hex_to_num(c)
    if not c or c == "" then return 0 end
    local n = string.byte(c)
    if not n then return 0 end
    if n >= 48 and n <= 57 then return n - 48 end
    if n >= 97 and n <= 102 then return n - 87 end
    if n >= 65 and n <= 70 then return n - 55 end
    return 0
end

function init_sprites()
    for sprite_id, hex_data in pairs(SPRITE_DATA) do
        local base_addr = 0x4000 + (sprite_id * 32)
        for row = 0, 7 do
            for col = 0, 3 do
                local idx = row * 8 + col * 2 + 1
                local hi = hex_to_num(hex_data:sub(idx, idx))
                local lo = hex_to_num(hex_data:sub(idx + 1, idx + 1))
                local byte_val = lo * 16 + hi
                poke(base_addr + row * 4 + col, byte_val)
            end
        end
    end
end

init_sprites()

-- =====================
-- CUSTOMER LOGIC
-- =====================
function spawn_customer()
    if #customers >= max_customers then return end

    -- Calculate spawn rate with promos
    local rate_mult = 1.0
    for _, p in ipairs(promos) do
        if p.active then rate_mult = rate_mult * p.effect end
    end
    rate_mult = rate_mult * (1 + staff.djs * 0.2)

    -- Pick customer type based on chaos level
    local type_idx = 1
    local chaos_roll = math.random(100)
    if chaos_roll < game.chaos_level then
        -- Weird customer!
        type_idx = math.min(#customer_types, 3 + math.floor(game.chaos_level / 15))
    else
        type_idx = math.random(1, math.min(3, #customer_types))
    end

    local ctype = customer_types[type_idx]
    local slot = #customers + 1

    table.insert(customers, {
        type = ctype,
        patience = ctype.patience,
        max_patience = ctype.patience,
        state = "waiting",  -- waiting, served, leaving
        drink_wanted = nil,
        x = 30 + (slot - 1) * 28,
        y = 85,
        anim = 0,
    })

    -- Pick a random unlocked drink they want
    local available = {}
    for i, d in ipairs(drinks) do
        if d.unlocked then table.insert(available, i) end
    end
    if #available > 0 then
        customers[#customers].drink_wanted = available[math.random(#available)]
    else
        customers[#customers].drink_wanted = 1
    end
end

function update_customers()
    customer_spawn_timer = customer_spawn_timer + 1/60

    local spawn_rate = base_spawn_rate
    for _, p in ipairs(promos) do
        if p.active then spawn_rate = spawn_rate / p.effect end
    end
    spawn_rate = spawn_rate / (1 + staff.djs * 0.2)
    spawn_rate = math.max(0.5, spawn_rate)

    if customer_spawn_timer >= spawn_rate then
        spawn_customer()
        customer_spawn_timer = 0
    end

    -- Update each customer
    for i = #customers, 1, -1 do
        local c = customers[i]
        c.anim = c.anim + 1

        if c.state == "waiting" then
            c.patience = c.patience - 1/60

            -- Add chaos from impatient waiting
            if c.patience < c.max_patience * 0.3 then
                game.chaos_level = game.chaos_level + 0.01
            end

            if c.patience <= 0 then
                -- Customer leaves angry!
                c.state = "leaving"
                game.chaos_level = game.chaos_level + c.type.chaos
                add_message(c.x, c.y - 10, "ANGRY!", C.RED)
            end
        elseif c.state == "served" then
            -- Happy customer, leaving with tip
            c.y = c.y + 1
            if c.y > 140 then
                table.remove(customers, i)
            end
        elseif c.state == "leaving" then
            c.y = c.y + 2
            if c.y > 140 then
                table.remove(customers, i)
            end
        end
    end
end

-- =====================
-- BARTENDER LOGIC
-- =====================
function update_bartender()
    bartender.anim_frame = bartender.anim_frame + 1

    if bartender.state == "idle" then
        -- Look for a customer to serve
        if #customers > 0 then
            for _, c in ipairs(customers) do
                if c.state == "waiting" then
                    bartender.target_customer = c
                    bartender.current_drink = c.drink_wanted
                    bartender.state = "shaking"
                    bartender.progress = 0
                    break
                end
            end
        end
    elseif bartender.state == "shaking" then
        local drink = drinks[bartender.current_drink]
        local speed = staff.bartender_speed * staff.bartenders
        bartender.progress = bartender.progress + (speed / drink.time) / 60

        -- Add particles while shaking
        if game.frame % 5 == 0 then
            add_particle(bartender.x + 4, bartender.y, drink.chaos > 5 and C.RED or C.YELLOW)
        end

        if bartender.progress >= 1 then
            bartender.state = "pouring"
            bartender.progress = 0
        end
    elseif bartender.state == "pouring" then
        bartender.progress = bartender.progress + 0.05
        if bartender.progress >= 1 then
            bartender.state = "serving"
            bartender.progress = 0
        end
    elseif bartender.state == "serving" then
        -- Deliver drink to customer
        if bartender.target_customer and bartender.target_customer.state == "waiting" then
            local drink = drinks[bartender.current_drink]
            local profit = drink.price - drink.cost
            profit = profit * tip_mult * drink_mult * bartender.target_customer.type.tip_mult

            game.money = game.money + profit
            game.customers_served = game.customers_served + 1
            game.chaos_level = game.chaos_level + drink.chaos * chaos_reduction
            game.reputation = game.reputation + 1

            bartender.target_customer.state = "served"
            add_message(bartender.target_customer.x, bartender.target_customer.y - 15,
                       "+"..format_money(profit), C.LIME)

            -- Drink effects
            if drink.chaos >= 10 then
                for i = 1, 5 do
                    add_particle(bartender.target_customer.x + math.random(-10, 10),
                               bartender.target_customer.y + math.random(-10, 10),
                               math.random(1, 15))
                end
            end
        end

        bartender.state = "idle"
        bartender.target_customer = nil
        bartender.current_drink = nil
    end
end

-- Auto-serve from waiters
function update_waiters()
    if staff.waiters <= 0 then return end

    local drinks_per_frame = staff.waiters * staff.waiter_rate / 60

    -- Serve waiting customers automatically (basic drinks only)
    for _, c in ipairs(customers) do
        if c.state == "waiting" and c.drink_wanted <= 2 then  -- Only basic drinks
            if math.random() < drinks_per_frame then
                local drink = drinks[c.drink_wanted]
                local profit = drink.price - drink.cost
                profit = profit * tip_mult * drink_mult * c.type.tip_mult * 0.8  -- Waiters get less tips

                game.money = game.money + profit
                game.customers_served = game.customers_served + 1
                c.state = "served"
                add_message(c.x, c.y - 15, "+"..format_money(profit), C.SKY)
            end
        end
    end
end

-- =====================
-- CHAOS MANAGEMENT
-- =====================
function update_chaos()
    -- Natural chaos decay
    game.chaos_level = game.chaos_level - 0.01

    -- Bouncer effect
    game.chaos_level = game.chaos_level - (staff.bouncers * staff.bouncer_effect / 60)

    -- Clamp chaos
    game.chaos_level = math.max(0, math.min(100, game.chaos_level))

    -- High chaos effects
    if game.chaos_level >= 80 then
        -- Customers leave faster
        for _, c in ipairs(customers) do
            c.patience = c.patience - 0.05
        end
        -- Random fires/effects
        if game.frame % 30 == 0 then
            add_particle(math.random(160, 230), math.random(40, 100), C.RED)
        end
    end
end

-- =====================
-- PROMOTIONS
-- =====================
function update_promos()
    for _, p in ipairs(promos) do
        if p.active then
            p.timer = p.timer - 1/60
            if p.timer <= 0 then
                p.active = false
                add_message(120, 60, p.name.." ended!", C.GRAY)
            end
        end
    end
end

function start_promo(idx)
    local p = promos[idx]
    if not p.active and game.money >= p.cost then
        game.money = game.money - p.cost
        p.active = true
        p.timer = p.duration
        add_message(120, 60, p.name.." ACTIVE!", C.LIME)

        -- Immediate chaos from wild promos
        game.chaos_level = game.chaos_level + (p.chaos_mult - 1) * 10
    end
end

-- =====================
-- PURCHASE FUNCTIONS
-- =====================
function unlock_drink(idx)
    local d = drinks[idx]
    if not d.unlocked and d.unlock_cost and game.money >= d.unlock_cost then
        game.money = game.money - d.unlock_cost
        d.unlocked = true
        add_message(120, 60, d.name.." unlocked!", C.CYAN)
    end
end

function hire_staff(type)
    if type == "bartender" then
        if game.money >= staff.bartender_cost then
            game.money = game.money - staff.bartender_cost
            staff.bartenders = staff.bartenders + 1
            staff.bartender_cost = math.floor(staff.bartender_cost * 1.5)
        end
    elseif type == "waiter" then
        if game.money >= staff.waiter_cost then
            game.money = game.money - staff.waiter_cost
            staff.waiters = staff.waiters + 1
            staff.waiter_cost = math.floor(staff.waiter_cost * 1.5)
        end
    elseif type == "bouncer" then
        if game.money >= staff.bouncer_cost then
            game.money = game.money - staff.bouncer_cost
            staff.bouncers = staff.bouncers + 1
            staff.bouncer_cost = math.floor(staff.bouncer_cost * 1.5)
        end
    elseif type == "dj" then
        if game.money >= staff.dj_cost then
            game.money = game.money - staff.dj_cost
            staff.djs = staff.djs + 1
            staff.dj_cost = math.floor(staff.dj_cost * 1.5)
        end
    end
end

function buy_upgrade(category, idx)
    local u = upgrades[category][idx]
    if not u or u.owned then return end
    if game.money < u.cost then return end

    game.money = game.money - u.cost
    u.owned = true

    if category == "bar" then
        max_customers = max_customers + 1
        tip_mult = tip_mult * u.mult
    elseif category == "drinks" then
        drink_mult = drink_mult * u.mult
    elseif category == "chaos" then
        chaos_reduction = chaos_reduction * u.mult
    end

    add_message(120, 60, u.name.." bought!", C.LIME)
end

-- =====================
-- INPUT HANDLING
-- =====================
local mx, my, mb, pmb = 0, 0, false, false
local prev_my = 0
local dragging = false

function handle_input()
    local left
    mx, my, left = mouse()
    mb = left

    if mb and not pmb then
        dragging = false

        -- Tab buttons
        if my < 12 then
            if mx < 60 then game.tab = 1
            elseif mx < 120 then game.tab = 2
            elseif mx < 180 then game.tab = 3
            else game.tab = 4 end
        else
            handle_tab_click()
        end
    elseif mb and my >= UI_TOP and my < UI_BOTTOM then
        if dragging then
            local delta = prev_my - my
            game.scroll[game.tab] = game.scroll[game.tab] + delta
            if game.scroll[game.tab] < 0 then game.scroll[game.tab] = 0 end
        end
        dragging = true
    else
        dragging = false
    end

    prev_my = my
    pmb = mb
end

function handle_tab_click()
    if my < UI_TOP or my >= UI_BOTTOM then return end

    local scroll = game.scroll[game.tab]
    local adj_my = my + scroll
    local btn_width = 115

    if game.tab == 1 then  -- Drinks
        local y = UI_TOP + 8
        for i, d in ipairs(drinks) do
            local h = 18
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                if d.unlocked then
                    -- Already unlocked, maybe boost it?
                else
                    unlock_drink(i)
                end
            end
            y = y + h
        end

    elseif game.tab == 2 then  -- Staff
        local y = UI_TOP + 8
        local staff_items = {
            {name="Bartender", type="bartender", count=staff.bartenders, cost=staff.bartender_cost},
            {name="Waiter", type="waiter", count=staff.waiters, cost=staff.waiter_cost},
            {name="Bouncer", type="bouncer", count=staff.bouncers, cost=staff.bouncer_cost},
            {name="DJ", type="dj", count=staff.djs, cost=staff.dj_cost},
        }
        for _, s in ipairs(staff_items) do
            local h = 20
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                hire_staff(s.type)
            end
            y = y + h
        end

    elseif game.tab == 3 then  -- Promos
        local y = UI_TOP + 8
        for i, p in ipairs(promos) do
            local h = 18
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                start_promo(i)
            end
            y = y + h
        end

    elseif game.tab == 4 then  -- Upgrades
        local y = UI_TOP + 8
        for i, u in ipairs(upgrades.bar) do
            local h = 18
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                buy_upgrade("bar", i)
            end
            y = y + h
        end
        y = y + 10
        for i, u in ipairs(upgrades.drinks) do
            local h = 18
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                buy_upgrade("drinks", i)
            end
            y = y + h
        end
        y = y + 10
        for i, u in ipairs(upgrades.chaos) do
            local h = 18
            if adj_my >= y and adj_my < y + h and mx >= 4 and mx < 4 + btn_width then
                buy_upgrade("chaos", i)
            end
            y = y + h
        end
    end
end

-- =====================
-- GAME UPDATE
-- =====================
function update_game()
    game.frame = game.frame + 1
    if game.frame % 60 == 0 then
        game.time = game.time + 1
    end

    update_customers()
    update_bartender()
    update_waiters()
    update_chaos()
    update_promos()

    -- Update particles
    for i = #game.particles, 1, -1 do
        local p = game.particles[i]
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.life = p.life - 1
        if p.life <= 0 then
            table.remove(game.particles, i)
        end
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
end

-- =====================
-- DRAWING
-- =====================
function draw_game()
    cls(C.DARK)

    -- Draw bar background scene
    draw_bar_scene()

    -- Header
    rect(0, 0, 240, 12, C.NAVY)
    local tabs = {"DRINKS", "STAFF", "PROMOS", "UPGRADE"}
    for i, t in ipairs(tabs) do
        local x = (i-1) * 60
        local col = game.tab == i and C.WHITE or C.GREEN
        rect(x, 0, 59, 11, col)
        print(t, x + 10, 2, C.BLACK)
    end

    -- Draw current tab
    if game.tab == 1 then draw_drinks()
    elseif game.tab == 2 then draw_staff()
    elseif game.tab == 3 then draw_promos()
    else draw_upgrades_tab()
    end

    -- Status bar
    rect(0, 120, 240, 16, C.BLACK)
    rect(0, 122, 240, 14, C.DARK)
    print(format_money(game.money), 4, 126, C.LIME)
    print("Chaos:"..math.floor(game.chaos_level).."%", 70, 126,
          game.chaos_level > 60 and C.RED or (game.chaos_level > 30 and C.ORANGE or C.GREEN))
    print("Served:"..game.customers_served, 150, 126, C.CYAN)

    -- Chaos warning
    if game.chaos_level >= 80 then
        local flash = game.frame % 30 < 15
        if flash then
            print("!! CHAOS !!", 180, 126, C.RED)
        end
    end

    -- Particles
    for _, p in ipairs(game.particles) do
        pix(p.x, p.y, p.color)
    end

    -- Messages
    for _, m in ipairs(game.messages) do
        print(m.text, m.x, m.y, m.color)
    end
end

function draw_bar_scene()
    -- Background wall with wood paneling
    rect(130, 14, 110, 106, C.PURPLE)

    -- Decorative brick pattern on wall
    for row = 0, 4 do
        for col = 0, 6 do
            local bx = 132 + col * 16 + (row % 2) * 8
            local by = 16 + row * 10
            rect(bx, by, 14, 8, C.NAVY)
            rectb(bx, by, 14, 8, C.PURPLE)
        end
    end

    -- Neon sign glow effect
    local glow = math.sin(game.frame * 0.1) > 0
    if glow then
        rect(160, 18, 60, 16, C.CYAN)
    end
    rect(162, 20, 56, 12, C.NAVY)
    print("OPEN", 172, 23, glow and C.CYAN or C.TEAL)

    -- Bottle shelf with back lighting
    rect(135, 38, 100, 52, C.DARK)
    rect(135, 38, 100, 2, C.ORANGE)  -- Shelf edge
    rect(135, 58, 100, 2, C.ORANGE)  -- Middle shelf
    rect(135, 78, 100, 2, C.ORANGE)  -- Bottom shelf

    -- Detailed bottles on shelves with labels
    local bottle_colors = {
        {C.RED, C.GREEN, C.BLUE, C.YELLOW, C.CYAN, C.ORANGE, C.LIME},
        {C.SKY, C.PURPLE, C.WHITE, C.RED, C.GREEN, C.BLUE, C.ORANGE},
    }
    for row = 0, 1 do
        for i = 0, 6 do
            local bx = 138 + i * 14
            local by = 42 + row * 20
            local col = bottle_colors[row + 1][i + 1]

            -- Bottle body
            rect(bx, by, 8, 14, col)
            rect(bx + 2, by - 4, 4, 5, col)

            -- Bottle shine
            pix(bx + 1, by + 2, C.WHITE)

            -- Label
            rect(bx + 1, by + 6, 6, 4, C.WHITE)
        end
    end

    -- Bar counter with wood grain detail
    rect(130, 92, 110, 28, C.ORANGE)
    rect(130, 92, 110, 4, C.YELLOW)  -- Polished top
    -- Wood grain lines
    for i = 0, 10 do
        line(130, 98 + i * 2, 240, 98 + i * 2, 3)
    end

    -- Bar stools (empty ones)
    for i = 0, 2 do
        local sx = 135 + i * 30
        rect(sx, 108, 12, 8, C.RED)
        rect(sx + 2, 116, 2, 4, C.GRAY)
        rect(sx + 8, 116, 2, 4, C.GRAY)
    end

    -- Tip jar on counter
    rect(218, 85, 12, 14, C.SILVER)
    rect(220, 87, 8, 10, C.WHITE)
    -- Coins in jar
    for i = 0, 2 do
        pix(222 + i, 93 - i, C.YELLOW)
    end

    -- Glasses drying rack
    for i = 0, 3 do
        rect(200 + i * 8, 82, 6, 8, C.WHITE)
    end

    -- Bartender
    draw_bartender()

    -- Customers at bar
    draw_customers()

    -- Chaos effects - increasingly wild as chaos rises
    if game.chaos_level > 30 then
        -- Spilled drinks
        for i = 1, math.floor(game.chaos_level / 30) do
            local sx = 140 + math.random(80)
            local sy = 95 + math.random(10)
            local col = ({C.RED, C.YELLOW, C.ORANGE, C.LIME, C.CYAN})[math.random(5)]
            circ(sx, sy, 2, col)
        end
    end

    if game.chaos_level > 50 then
        -- Flying debris/sparkles
        for i = 1, math.floor(game.chaos_level / 15) do
            local px = 135 + math.random(100)
            local py = 40 + math.random(70)
            pix(px, py, ({C.RED, C.YELLOW, C.ORANGE, C.WHITE})[math.random(4)])
        end

        -- Smoke wisps
        if game.frame % 3 == 0 then
            local smoke_x = 160 + math.random(60)
            local smoke_y = 50 + math.sin(game.frame * 0.1) * 5
            pix(smoke_x, smoke_y, C.GRAY)
        end
    end

    if game.chaos_level > 70 then
        -- Fire sprites
        local fire_frame = (game.frame // 8) % 2
        for i = 1, math.floor((game.chaos_level - 70) / 10) do
            spr(64 + fire_frame, 140 + math.random(80), 60 + math.random(30), 0)
        end

        -- Screen shake effect
        if game.frame % 5 == 0 then
            -- Subtle shake via offset drawing would go here
        end
    end

    if game.chaos_level > 90 then
        -- Complete mayhem - broken glass everywhere
        for i = 1, 5 do
            spr(71, 135 + math.random(95), 85 + math.random(25), 0)
        end
    end

    -- Active promo indicators with icons
    local promo_y = 16
    for _, p in ipairs(promos) do
        if p.active then
            local flash = (game.frame % 20) < 10
            rect(132, promo_y, 50, 8, flash and C.GREEN or C.LIME)
            print(p.name:sub(1, 7), 134, promo_y + 1, C.BLACK)
            promo_y = promo_y + 10
            if promo_y > 36 then break end
        end
    end

    -- Music notes floating if DJ is active
    if staff.djs > 0 then
        local note_y = 30 + math.sin(game.frame * 0.1) * 5
        spr(60, 220, note_y, 0)
        if staff.djs > 1 then
            spr(60, 210, note_y + 10, 0, 1, 1)
        end
    end
end

function draw_bartender()
    local bx, by = 185, 78
    local sprite_id = 48  -- idle

    -- Idle bobbing animation
    local idle_bob = math.sin(game.frame * 0.05) * 1

    if bartender.state == "idle" then
        sprite_id = 48
        by = by + idle_bob

        -- Occasionally wipe counter when idle
        if (game.frame % 180) < 30 then
            sprite_id = 52  -- cleaning
        end
    elseif bartender.state == "shaking" then
        sprite_id = 49
        -- Vigorous shake animation
        bx = bx + math.sin(game.frame * 0.8) * 4
        by = by + math.cos(game.frame * 0.6) * 2

        -- Shake particles
        if game.frame % 4 == 0 then
            add_particle(bx + 4 + math.random(-3, 3), by - 5,
                        ({C.WHITE, C.CYAN, C.YELLOW})[math.random(3)],
                        math.random(-1, 1) * 0.5, -1)
        end
    elseif bartender.state == "pouring" then
        sprite_id = 50

        -- Pouring liquid effect
        if bartender.progress < 0.8 then
            local pour_x = bx + 10
            local pour_y = by - 2 + bartender.progress * 10
            local drink = drinks[bartender.current_drink]
            local pour_col = drink.chaos > 5 and C.RED or (drink.chaos > 0 and C.ORANGE or C.YELLOW)
            line(pour_x, by - 2, pour_x, pour_y, pour_col)
        end
    elseif bartender.state == "serving" then
        sprite_id = 51

        -- Arm extended with drink sliding
        local slide_x = bx - 20 + (1 - bartender.progress) * 20
        if bartender.current_drink then
            spr(drinks[bartender.current_drink].icon, slide_x, by - 4, 0)
        end
    end

    -- Draw shadow
    elli(bx + 4, by + 12, 6, 2, C.BLACK)

    -- Draw bartender sprite
    spr(sprite_id, bx, by, 0)

    -- Progress bar when making drink
    if bartender.state == "shaking" or bartender.state == "pouring" then
        -- Background
        rect(bx - 4, by - 10, 16, 4, C.DARK)
        rectb(bx - 4, by - 10, 16, 4, C.GRAY)
        -- Fill
        local fill_col = C.LIME
        if bartender.progress > 0.7 then fill_col = C.YELLOW end
        if bartender.progress > 0.9 then fill_col = C.WHITE end
        rect(bx - 3, by - 9, math.floor(14 * bartender.progress), 2, fill_col)
    end

    -- Show current drink being made above bartender
    if bartender.current_drink and bartender.state == "shaking" then
        local drink = drinks[bartender.current_drink]
        local float_y = by - 16 + math.sin(game.frame * 0.3) * 2
        spr(drink.icon, bx + 2, float_y, 0)

        -- Sparkle effect for chaos drinks
        if drink.chaos > 5 then
            local sparkle_frame = (game.frame // 6) % 2
            spr(66 + sparkle_frame, bx + 6, float_y - 4, 0)
        end
    end

    -- Speech bubble when idle sometimes
    if bartender.state == "idle" and (game.frame % 300) < 60 then
        rect(bx + 10, by - 16, 24, 10, C.WHITE)
        print("Hi!", bx + 14, by - 14, C.BLACK)
        -- Bubble tail
        pix(bx + 12, by - 6, C.WHITE)
        pix(bx + 11, by - 7, C.WHITE)
    end
end

function draw_customers()
    -- Draw customer area floor tiles first
    for i = 0, 5 do
        local tile_x = 5 + i * 22
        rect(tile_x, 100, 20, 20, (i % 2 == 0) and C.DARK or C.NAVY)
    end

    for i, c in ipairs(customers) do
        local cx = 15 + (i-1) * 22
        local cy = 88

        -- Different animations based on state
        local bob = 0
        local flip = 0

        if c.state == "waiting" then
            -- Impatient bobbing - faster as patience decreases
            local pct = c.patience / c.max_patience
            local bob_speed = 0.1 + (1 - pct) * 0.15
            bob = math.sin(c.anim * bob_speed) * (2 + (1 - pct) * 2)

            -- Turn to look at bartender occasionally
            if (c.anim % 120) < 30 then
                flip = 1
            end
        elseif c.state == "served" then
            -- Happy bounce as they leave
            bob = math.abs(math.sin(c.anim * 0.2)) * -4
            cy = cy + (c.y - 85)
        elseif c.state == "leaving" then
            -- Angry stomping motion
            bob = math.abs(math.sin(c.anim * 0.3)) * 2
            cy = cy + (c.y - 85)
        end

        -- Draw shadow
        elli(cx + 4, cy + 12, 5, 2, C.BLACK)

        -- Draw customer sprite
        spr(c.type.sprite, cx, cy + bob, 0, 1, flip)

        -- Patience bar with fancy border
        if c.state == "waiting" then
            local pct = c.patience / c.max_patience
            local bar_col = pct > 0.6 and C.GREEN or (pct > 0.3 and C.YELLOW or C.RED)

            -- Bar background
            rect(cx - 1, cy - 6, 10, 4, C.DARK)
            rectb(cx - 1, cy - 6, 10, 4, C.GRAY)
            -- Bar fill
            rect(cx, cy - 5, math.floor(8 * pct), 2, bar_col)

            -- Drink wanted bubble
            if c.drink_wanted then
                -- Thought bubble
                rect(cx - 2, cy - 18, 12, 10, C.WHITE)
                pix(cx + 2, cy - 8, C.WHITE)
                pix(cx + 4, cy - 9, C.WHITE)
                -- Drink icon inside bubble
                spr(drinks[c.drink_wanted].icon, cx, cy - 16, 0)
            end

            -- Impatience effects
            if pct < 0.3 then
                -- Angry symbols
                local flash = (c.anim % 10) < 5
                if flash then
                    print("!!", cx + 8, cy - 4 + bob, C.RED)
                end

                -- Steam coming off head for very impatient
                if pct < 0.15 and c.anim % 8 == 0 then
                    add_particle(cx + 4, cy - 2, C.WHITE, 0, -1.5)
                end
            end

            -- Special customer effects
            if c.type.name == "Ghost" then
                -- Ghostly glow
                if game.frame % 3 == 0 then
                    pix(cx + math.random(8), cy + math.random(8), C.WHITE)
                end
            elseif c.type.name == "Dragon" then
                -- Smoke from nostrils
                if game.frame % 10 == 0 then
                    add_particle(cx + 6, cy + 2, C.GRAY, 1, -0.5)
                end
            elseif c.type.name == "Robot" then
                -- Blinking lights
                local blink = (game.frame % 20) < 10
                pix(cx + 2, cy + 2, blink and C.LIME or C.RED)
            elseif c.type.name == "Alien" then
                -- Antenna glow
                pix(cx + 4, cy - 1, (game.frame % 6) < 3 and C.LIME or C.GREEN)
            end
        elseif c.state == "served" then
            -- Happy effects
            local hearts = {"<3", ":D", "YAY"}
            print(hearts[(c.anim // 20 % 3) + 1], cx, cy - 6 + bob, C.LIME)

            -- Stars around happy customer
            if c.anim % 15 == 0 then
                add_particle(cx + math.random(8), cy + math.random(8), C.YELLOW, math.random(-1, 1) * 0.5, -1)
            end
        elseif c.state == "leaving" then
            -- Angry effects
            local angry = {"@#$!", ">:(", "BAD!"}
            print(angry[(c.anim // 15 % 3) + 1], cx - 4, cy - 6 + bob, C.RED)
        end
    end

    -- Show empty slots with subtle indicators
    for i = #customers + 1, max_customers do
        local cx = 15 + (i-1) * 22
        -- Subtle dotted outline showing potential customer spot
        if game.frame % 60 < 30 then
            rectb(cx - 1, 87, 10, 12, C.NAVY)
        end
    end

    -- Customer count indicator
    local count_col = #customers >= max_customers and C.RED or C.GREEN
    print(#customers.."/"..max_customers, 4, 92, count_col)
end

function draw_drinks()
    local scroll = game.scroll[1]
    local y = UI_TOP + 8 - scroll
    local btn_w = 115

    for i, d in ipairs(drinks) do
        if y >= UI_TOP - 18 and y < UI_BOTTOM then
            local bg_col = d.unlocked and C.GREEN or C.TEAL
            if game.money < (d.unlock_cost or 0) and not d.unlocked then
                bg_col = C.NAVY
            end

            rect(4, y, btn_w, 16, bg_col)

            -- Drink icon
            spr(d.icon, 6, y + 4, 0)

            -- Name and price
            print(d.name, 18, y + 2, C.BLACK)
            if d.unlocked then
                print("$"..d.price.." profit", 18, y + 9, C.DARK)
            else
                print("Unlock: "..format_money(d.unlock_cost), 18, y + 9, C.NAVY)
            end

            -- Chaos indicator
            if d.chaos > 0 then
                local chaos_col = d.chaos > 10 and C.RED or (d.chaos > 5 and C.ORANGE or C.YELLOW)
                print("+"..d.chaos, btn_w - 12, y + 2, chaos_col)
            end
        end
        y = y + 18
    end
end

function draw_staff()
    local scroll = game.scroll[2]
    local y = UI_TOP + 8 - scroll
    local btn_w = 115

    local staff_items = {
        {name="Bartender", desc="Faster mixing", count=staff.bartenders, cost=staff.bartender_cost, sprite=48},
        {name="Waiter", desc="Auto-serve basic", count=staff.waiters, cost=staff.waiter_cost, sprite=32},
        {name="Bouncer", desc="Reduce chaos", count=staff.bouncers, cost=staff.bouncer_cost, sprite=35},
        {name="DJ", desc="More customers", count=staff.djs, cost=staff.dj_cost, sprite=55},
    }

    for _, s in ipairs(staff_items) do
        if y >= UI_TOP - 20 and y < UI_BOTTOM then
            local can_afford = game.money >= s.cost
            local bg_col = can_afford and C.SKY or C.NAVY

            rect(4, y, btn_w, 18, bg_col)
            spr(s.sprite, 6, y + 5, 0)

            print(s.name.." x"..s.count, 18, y + 2, C.BLACK)
            print(s.desc, 18, y + 9, C.DARK)
            print(format_money(s.cost), btn_w - 30, y + 5, C.NAVY)
        end
        y = y + 20
    end
end

function draw_promos()
    local scroll = game.scroll[3]
    local y = UI_TOP + 8 - scroll
    local btn_w = 115

    for i, p in ipairs(promos) do
        if y >= UI_TOP - 18 and y < UI_BOTTOM then
            local bg_col
            if p.active then
                bg_col = C.LIME
            elseif game.money >= p.cost then
                bg_col = C.SKY
            else
                bg_col = C.NAVY
            end

            rect(4, y, btn_w, 16, bg_col)
            print(p.name, 6, y + 2, C.BLACK)
            print(p.desc, 6, y + 9, C.DARK)

            if p.active then
                print(math.floor(p.timer).."s", btn_w - 20, y + 5, C.GREEN)
            else
                print(format_money(p.cost), btn_w - 30, y + 5, C.NAVY)
            end
        end
        y = y + 18
    end
end

function draw_upgrades_tab()
    local scroll = game.scroll[4]
    local y = UI_TOP + 8 - scroll
    local btn_w = 115

    -- Bar upgrades
    if y >= UI_TOP then print("BAR", 4, y, C.CYAN) end
    y = y + 10
    for i, u in ipairs(upgrades.bar) do
        if y >= UI_TOP - 18 and y < UI_BOTTOM then
            local bg_col = u.owned and C.GREEN or (game.money >= u.cost and C.SKY or C.NAVY)
            rect(4, y, btn_w, 16, bg_col)
            print(u.name, 6, y + 2, C.BLACK)
            print(u.desc, 6, y + 9, C.DARK)
            if not u.owned then
                print(format_money(u.cost), btn_w - 30, y + 5, C.NAVY)
            else
                print("[OK]", btn_w - 20, y + 5, C.GREEN)
            end
        end
        y = y + 18
    end

    -- Drink upgrades
    y = y + 5
    if y >= UI_TOP then print("DRINKS", 4, y, C.ORANGE) end
    y = y + 10
    for i, u in ipairs(upgrades.drinks) do
        if y >= UI_TOP - 18 and y < UI_BOTTOM then
            local bg_col = u.owned and C.GREEN or (game.money >= u.cost and C.SKY or C.NAVY)
            rect(4, y, btn_w, 16, bg_col)
            print(u.name, 6, y + 2, C.BLACK)
            print(u.desc, 6, y + 9, C.DARK)
            if not u.owned then
                print(format_money(u.cost), btn_w - 30, y + 5, C.NAVY)
            else
                print("[OK]", btn_w - 20, y + 5, C.GREEN)
            end
        end
        y = y + 18
    end

    -- Chaos upgrades
    y = y + 5
    if y >= UI_TOP then print("CHAOS CONTROL", 4, y, C.RED) end
    y = y + 10
    for i, u in ipairs(upgrades.chaos) do
        if y >= UI_TOP - 18 and y < UI_BOTTOM then
            local bg_col = u.owned and C.GREEN or (game.money >= u.cost and C.SKY or C.NAVY)
            rect(4, y, btn_w, 16, bg_col)
            print(u.name, 6, y + 2, C.BLACK)
            print(u.desc, 6, y + 9, C.DARK)
            if not u.owned then
                print(format_money(u.cost), btn_w - 30, y + 5, C.NAVY)
            else
                print("[OK]", btn_w - 20, y + 5, C.GREEN)
            end
        end
        y = y + 18
    end
end

-- =====================
-- SPLASH SCREEN
-- =====================
local splash_customers = {}
for i = 1, 8 do
    table.insert(splash_customers, {
        x = math.random(20, 220),
        y = math.random(95, 120),
        sprite = 32 + math.random(0, 11),
        dir = math.random() > 0.5 and 1 or -1,
        speed = 0.3 + math.random() * 0.4,
        drink = math.random(1, 11),
        has_drink = math.random() > 0.5,
    })
end

local splash_bubbles = {}
local splash_stars = {}

function update_splash()
    game.frame = game.frame + 1

    -- Update customers
    for _, c in ipairs(splash_customers) do
        c.x = c.x + c.dir * c.speed
        if c.x < 20 then c.x = 20 c.dir = 1
        elseif c.x > 220 then c.x = 220 c.dir = -1 end

        -- Random direction changes
        if math.random() < 0.005 then
            c.dir = -c.dir
        end
    end

    -- Spawn bubbles
    if game.frame % 20 == 0 then
        table.insert(splash_bubbles, {
            x = math.random(50, 190),
            y = 90,
            size = math.random(1, 3),
            speed = 0.5 + math.random() * 0.5,
        })
    end

    -- Update bubbles
    for i = #splash_bubbles, 1, -1 do
        local b = splash_bubbles[i]
        b.y = b.y - b.speed
        b.x = b.x + math.sin(game.frame * 0.1 + i) * 0.3
        if b.y < 10 then
            table.remove(splash_bubbles, i)
        end
    end

    -- Spawn stars
    if game.frame % 30 == 0 then
        table.insert(splash_stars, {
            x = math.random(240),
            y = math.random(80),
            life = 60,
        })
    end

    -- Update stars
    for i = #splash_stars, 1, -1 do
        local s = splash_stars[i]
        s.life = s.life - 1
        if s.life <= 0 then
            table.remove(splash_stars, i)
        end
    end
end

function draw_splash()
    cls(C.DARK)

    -- Gradient background (night sky to bar)
    for y = 0, 40 do
        local col = y < 20 and C.NAVY or C.PURPLE
        line(0, y, 240, y, col)
    end

    -- Stars in sky
    for _, s in ipairs(splash_stars) do
        local twinkle = (s.life % 10) < 5
        pix(s.x, s.y, twinkle and C.WHITE or C.YELLOW)
    end

    -- Moon
    circ(210, 20, 12, C.YELLOW)
    circ(215, 18, 10, C.DARK)  -- Crescent effect

    -- Bar exterior wall
    rect(0, 40, 240, 96, C.PURPLE)

    -- Brick pattern
    for row = 0, 5 do
        for col = 0, 15 do
            local bx = col * 16 + (row % 2) * 8
            local by = 42 + row * 10
            rect(bx, by, 14, 8, C.NAVY)
        end
    end

    -- Entrance door
    rect(95, 70, 50, 50, C.ORANGE)
    rect(100, 75, 40, 40, C.DARK)
    -- Door window
    rect(108, 80, 24, 20, C.YELLOW)
    -- Door handle
    circ(130, 100, 2, C.YELLOW)

    -- Giant neon sign with glow
    local glow_intensity = (math.sin(game.frame * 0.08) + 1) / 2
    local glow_color = glow_intensity > 0.5 and C.CYAN or C.SKY

    -- Sign background
    rect(30, 5, 180, 55, C.DARK)
    rectb(30, 5, 180, 55, glow_color)
    rectb(32, 7, 176, 51, glow_color)
    rectb(34, 9, 172, 47, C.NAVY)

    -- Glow effect behind text
    if glow_intensity > 0.7 then
        for i = 1, 3 do
            rect(50 + i, 18 + i, 140, 30, C.NAVY)
        end
    end

    -- Title text with neon effect
    local text_offset = math.sin(game.frame * 0.05) * 1

    -- Shadow
    print("THE TIPSY", 56, 16, C.NAVY, false, 2)
    print("TAVERN", 68, 34, C.NAVY, false, 2)

    -- Main text
    print("THE TIPSY", 55 + text_offset, 15, C.RED, false, 2)
    print("TAVERN", 67 + text_offset, 33, C.ORANGE, false, 2)

    -- Decorative cocktail glass icons
    spr(1, 38, 20, 0)
    spr(2, 190, 20, 0)
    spr(3, 38, 40, 0)
    spr(4, 190, 40, 0)

    -- Windows with light
    rect(10, 50, 30, 25, C.ORANGE)
    rect(15, 55, 20, 15, C.YELLOW)
    rect(200, 50, 30, 25, C.ORANGE)
    rect(205, 55, 20, 15, C.YELLOW)

    -- Silhouettes in windows
    if game.frame % 60 < 40 then
        rect(20, 58, 6, 10, C.DARK)
        rect(210, 60, 8, 8, C.DARK)
    end

    -- Ground/sidewalk
    rect(0, 118, 240, 18, C.GRAY)
    for i = 0, 12 do
        rect(i * 20, 120, 18, 14, C.SILVER)
    end

    -- Animated customers walking by
    for _, c in ipairs(splash_customers) do
        local bob = math.sin(game.frame * 0.12 + c.x * 0.1) * 2
        local flip = c.dir < 0 and 1 or 0

        -- Shadow
        elli(c.x + 4, c.y + 10, 4, 2, C.BLACK)

        -- Customer sprite
        spr(c.sprite, c.x, c.y + bob, 0, 1, flip)

        -- Some have drinks
        if c.has_drink then
            spr(c.drink, c.x + (flip == 0 and 6 or -6), c.y + bob + 2, 0)
        end
    end

    -- Floating bubbles
    for _, b in ipairs(splash_bubbles) do
        circ(b.x, b.y, b.size, C.CYAN)
    end

    -- Bartender waving from door
    local wave_frame = (game.frame // 20) % 2
    spr(48 + wave_frame, 115, 100, 0)

    -- "OPEN" sign on door
    local open_flash = (game.frame % 40) < 20
    rect(102, 68, 36, 8, open_flash and C.LIME or C.GREEN)
    print("OPEN", 110, 69, C.BLACK)

    -- Start prompt with animation
    local pulse = (math.sin(game.frame * 0.1) + 1) / 2
    local prompt_col = pulse > 0.5 and C.WHITE or C.CYAN

    rect(55, 124, 130, 12, C.BLACK)
    rectb(55, 124, 130, 12, prompt_col)

    -- Bouncing arrow
    local arrow_bob = math.sin(game.frame * 0.15) * 2
    print(">", 60, 126 + arrow_bob, prompt_col)
    print("TAP TO OPEN BAR", 70, 127, prompt_col)
    print("<", 175, 126 - arrow_bob, prompt_col)
end

function handle_splash_input()
    local _, _, mb = mouse()
    if mb and not pmb then
        game.state = "playing"
    end
    pmb = mb
end

-- =====================
-- MAIN LOOP
-- =====================
function TIC()
    if game.state == "splash" then
        update_splash()
        draw_splash()
        handle_splash_input()
    else
        handle_input()
        update_game()
        draw_game()
    end
end
