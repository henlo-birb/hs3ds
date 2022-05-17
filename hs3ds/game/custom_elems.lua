require("elems")

local function renderMultAnimation(this, app)
    local width = this:get("width")
    local height = this:get("height")
    for _, anim in pairs(this.anims) do anim:render(app) end
    if this:get("show_scroll_bar") and #this.anims > 1 then 
        local scroll_bar_width = this:get("scroll_bar_width")
        love.graphics.setColor({1,1,1})
        love.graphics.rectangle("fill", getX(this) + width * this:get("sx"), getY(this), scroll_bar_width + 4, height * this:get("sy"))
        love.graphics.setColor(this:get("scroll_bar_color"))
        love.graphics.rectangle("fill", getX(this) + (width * this:get("sx")) + 2, getY(this) +
                                        this.scroll_bar_scale * this.scroll_y * this:get("sy"),
                                        scroll_bar_width,
                                    this.scroll_bar_height * this:get("sy"))
    end
end

local function updateMultAnimation(this, app, dt)
    local names = this:get("names")
    local padding = this:get("padding")
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
            local new_anim = Animation(name, getX(this),
                                       getY(this) + base_y)
            new_anim["base_y"] = base_y
            new_anim:update(app, 0)
            table.insert(this.anims, new_anim)
        end
        local height = this:get("height")
        local total_height = this.scroll_limit + this.anims[#this.anims].height + padding
        this.scroll_bar_height = height * height / total_height
        this.scroll_bar_scale = (height - this.scroll_bar_height) / (total_height - height)
        this.last_names = names
    end

    local delta_scroll = this:get("delta_scroll")

    if math.abs(delta_scroll) > 0.2 then
        this.scroll_y = this.scroll_y + delta_scroll * 2
        this.scroll_y = math.min(this.scroll_y, this.scroll_limit)
        this.scroll_y = math.max(this.scroll_y, 0)
    end

    for _, anim in pairs(this.anims) do
        anim.y = anim.base_y + getY(this) - this.scroll_y * this:get("sy")
        anim.x = getX(this)
    end
    
    for _, anim in pairs(this.anims) do
        anim.sx =this:get("sx")
        anim.sy = this:get("sy")
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
        delta_scroll = 0,
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
        get = get,
        p = merge
    }
end

local function renderPopupLabel(this, app) 
    local padding = this:get("padding")
    local x = getX(this)
    local y = getY(this)
    local font = this:get("font")
    if this:get("show_background") then 
        love.graphics.setColor(this:get("background_color"))
        this.rect_width = font:getWidth(this.text_string) + padding * 2 + 7
        this.rect_height = font:getHeight() + padding * 2
        love.graphics.rectangle("fill", x, y, this.rect_width, this.rect_height, this:get("background_radius"))
        love.graphics.setCanvas()
        x = x + padding
        y = y + padding
    end
    love.graphics.setFont(font)
    love.graphics.printf(this.text, x, y, this:get("wrap_limit"))
end

local function updatePopupLabel(this, app, dt) 
    if this.visible then
        if not this.was_visible then
            this.dt = 0
        end
        this.dt = this.dt + dt
        if this.dt > this:get("display_time") then
            this.visible = false
        end
    end
    this.was_visible = this.visible
end


function PopupLabel(x, y) 
    return {
        type = "text",
        dt = 0,
        x = x or 0,
        y = y or 0,
        text = coloredtext,
        text_string = "",
        font = font or love.graphics.getFont(),
        display_time = 0,
        visible = false,
        was_visible = false,
        show_background = true,
        background_color = {1,1,1},
        background_radius = nil,
        rect_width = 0,
        rect_height = 0,
        padding = 5,
        wrap_limit = function(this)
            local width = love.graphics.getWidth(screen) - getX(this)
            this.wrap_limit = width
            return width
        end,
        display = function(this, text, time, font) 
            this.visible = true
            this.text = text
            this.display_time = time
            this.font = font or love.graphics.getFont()
            this.text_string = text
            if type(text) == "table" then
                this.text_string = ""
                for i = 2, #text, 2 do
                    this.text_string = this.text_string .. text[i]
                end
            else
                this.text_string = text
            end
        end,
        render = renderPopupLabel,
        update = updatePopupLabel,
        get = get,
        p = merge
    }
end

