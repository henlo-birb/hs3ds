require("elems")

local function renderMultAnimation(this, app)
    for _, anim in pairs(this.anims) do anim:render(app) end
end

local function updateMultAnimation(this, app, dt)
    local c = makeC(this)
    local names = c(this.names)
    local padding = c(this.padding)
    local scroll_y = c(this.scroll_y)
    if names ~= this.last_names then
        for _, anim in pairs(this.anims) do anim:release() end
        this.anims = {}
        this.last_scroll_y = 0

        this.scroll_limit = 0
        for _, name in pairs(names) do
            if #this.anims > 0 then
                this.scroll_limit = this.scroll_limit +
                                        this.anims[#this.anims].height + padding
            end
            local base_y = this.scroll_limit
            local new_anim = Animation(name, getX(this, c),
                                       getY(this, c) + base_y)
            new_anim["base_y"] = base_y
            new_anim:update(app, 0)
            table.insert(this.anims, new_anim)
        end
        this.last_names = names
    end

    if this.last_scroll_y ~= scroll_y then
        scroll_y = math.min(scroll_y, this.scroll_limit)
        scroll_y = math.max(scroll_y, 0)
        
        for _, anim in pairs(this.anims) do
            anim.y = anim.base_y + getY(this, c) - scroll_y
        end
        this.last_scroll_y = scroll_y
    end
    
    for _, anim in pairs(this.anims) do
        anim:update(app, dt)
    end
end

function MultAnimation(names, x, y, sx, sy, looping)
    return {
        type = "animation",
        names = names,
        last_names = {},
        anims = {},
        scroll_y = 0,
        last_scroll_y = -1,
        scroll_limit = 0,
        dt = 0,
        x = x or 0,
        y = y or 0,
        sx = sx or 1,
        sy = sy or 1,
        padding = 0,
        looping = looping == nil or looping, -- default true
        render = renderMultAnimation,
        update = updateMultAnimation,
        p = merge
    }
end
