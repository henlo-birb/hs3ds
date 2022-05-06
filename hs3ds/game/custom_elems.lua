require("elems")

local function renderMultAnimation(this, app)
    local c = makeC(this)
    local width = c(this.width)
    local height = c(this.height)
    for _, anim in pairs(this.anims) do anim:render(app) end
    if c(this.show_scroll_bar) and #this.anims > 1 then 
        local scroll_bar_width = c(this.scroll_bar_width)
        love.graphics.setColor({1,1,1})
        love.graphics.rectangle("fill", getX(this, c) + width, getY(this, c), scroll_bar_width + 4, height)
        love.graphics.setColor(c(this.scroll_bar_color))
        love.graphics.rectangle("fill", getX(this, c) + width + 2, getY(this, c) +
                                        this.scroll_bar_scale *
                                        this.scroll_y, scroll_bar_width,
                                    this.scroll_bar_height)
    end
end

local function updateMultAnimation(this, app, dt)
    local c = makeC(this)
    local names = c(this.names)
    local padding = c(this.padding)
    if names ~= this.last_names then
        for _, anim in pairs(this.anims) do anim:release() end
        this.anims = {}
        this.scroll_y = 0

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
        local height = c(this.height)
        local total_height = this.scroll_limit + this.anims[#this.anims].height + padding
        this.scroll_bar_height = height * height / total_height
        this.scroll_bar_scale = (height - this.scroll_bar_height) / (total_height - height)
        this.last_names = names
    end

    if math.abs(app.model.image_delta_scroll) > 0.2 then
        this.scroll_y = this.scroll_y + app.model.image_delta_scroll * 2
        this.scroll_y = math.min(this.scroll_y, this.scroll_limit)
        this.scroll_y = math.max(this.scroll_y, 0)
        
        for _, anim in pairs(this.anims) do
            anim.y = anim.base_y + getY(this, c) - this.scroll_y
        end
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
        scroll_limit = 0,
        dt = 0,
        x = x or 0,
        y = y or 0,
        sx = sx or 1,
        sy = sy or 1,
        padding = 0,
        looping = looping == nil or looping, -- default true
        width = 299,
        height = 207,
        show_scroll_bar = true,
        scroll_bar_color = {0.66275, 0.66275, 0.66275},
        scroll_bar_width = 5,
        scroll_bar_height = 20,
        scroll_bar_scale = 0,
        render = renderMultAnimation,
        update = updateMultAnimation,
        p = merge
    }
end
