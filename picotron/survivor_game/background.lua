-- Starry background system

local background_module = {}

function background_module.init_background()
    stars = {}
    for i = 1, 50 do
        add(stars, {
            x = rnd(480),
            y = rnd(270),
            speed = rnd(2) + 0.5,
            color = flr(rnd(3)) + 5
        })
    end
end

function background_module.update_background()
    for star in all(stars) do
        star.y += star.speed
        if star.y > 270 then
            star.y = 0
            star.x = rnd(480)
        end
    end
end

function background_module.draw_background()
    for star in all(stars) do
        pset(star.x, star.y, star.color)
    end
end

return background_module