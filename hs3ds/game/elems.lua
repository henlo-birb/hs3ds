require("utils")
function makeC(this)
    return function(a)
        ret = a
        if type(a) == "function" then ret = a(this) end
        return ret
    end
end

function getX(this, c)
    local x = c(this.x)
    if this.parent and this.position ~= "absolute" then
        x = x + getX(this.parent, makeC(this.parent))
    end
    return x
end

function getY(this, c)
    local y = c(this.y)
    if this.parent and this.position ~= "absolute" then
        y = y + getY(this.parent, makeC(this.parent))
    end
    return y
end

local function renderRectangle(this, app)
    local c = makeC(this)
    love.graphics.setColor(c(this.color))
    mode = c(this.mode)
    x = getX(this, c)
    y = getY(this, c)
    width = c(this.width)
    height = c(this.height)
    if mode == "dashed" then
        love.graphics.dashedLine(c(this.dash_length), c(this.space_length), 
        x, y, 
        x, y + height, 
        x + width, y + height,
        x + width, y,
        x, y
    )
    else
        love.graphics.rectangle(mode, x, y, width, height)
    end
    
end

function Rectangle(x, y, width, height, color, mode)
    return {
        type = "rectangle",
        x = x or 0,
        y = y or 0,
        width = width,
        height = height,
        dash_length = 5,
        space_length = 5,
        color = color or {love.graphics.getBackgroundColor()},
        mode = mode or "fill",
        render = renderRectangle,
        p = merge
    }
end

local function renderSimpleText(this, app)
    local c = makeC(this)
    love.graphics.setFont(c(this.font))
    love.graphics.print({c(this.color), c(this.text)}, getX(this, c),
                        getY(this, c))
end

function SimpleText(text, x, y, color, font)
    local font = font or love.graphics.getFont()
    local color = color or {0, 0, 0}
    return {
        type = "text",
        x = x or 0,
        y = y or 0,
        text = text,
        color = color,
        font = font,
        render = renderSimpleText,
        p = merge
    }
end

local function renderText(this, app)
    local c = makeC(this)
    love.graphics.draw(this.text_obj, getX(this, c), getY(this, c), c(this.r),
                       c(this.sx), c(this.sy), c(this.ox), c(this.oy),
                       c(this.kx), c(this.ky))
end

local function updateText(this, app)
    local c = makeC(this)
    local text = c(this.coloredtext)
    if this.last_text ~= text then
        this.text_obj:setf(text, c(this.wrap_limit), c(this.align))
        this.last_text = text
    end
end

function Text(coloredtext, font, x, y, wrap_limit, align)
    local font = font or love.graphics.getFont()
    return {
        type = "text",
        coloredtext = coloredtext,
        last_text = {},
        text_obj = love.graphics.newText(font),
        font = font,
        x = x or 0,
        y = y or 0,
        r = 0,
        sx = 1,
        sy = 1,
        kx = 0,
        ky = 0,
        ox = 0,
        oy = 0,
        wrap_limit = wrap_limit or function(this)
            local width = love.graphics.getWidth(screen);
            this.wrap_limit = width;
            return width
        end,
        align = align or "left",
        render = renderText,
        update = updateText,
        p = merge
    }
end

local function renderScrollableText(this, app)
    local c = makeC(this)
    local font = c(this.font)
    if font ~= this.last_font then
        this.text_obj:setFont(font)
        this.last_font = font
    end
    local text = c(this.coloredtext)
    local wrap_limit = c(this.wrap_limit)
    local view_height = c(this.view_height)
    local scroll_bar_color = c(this.scroll_bar_color)
    local scroll_bar_width = c(this.scroll_bar_width)
    if #text > 0 then
        love.graphics.setCanvas()
        love.graphics.setScissor(getX(this, c), getY(this, c), wrap_limit,
                                 view_height)
        love.graphics.draw(this.text_obj, getX(this, c),
                           getY(this, c) - this.scroll_y, c(this.r), c(this.sx),
                           c(this.sy), c(this.ox), c(this.oy), c(this.kx),
                           c(this.ky))
        if not (this.scroll_start and this.scroll_end) and c(this.show_scroll_bar) then
            love.graphics.setColor(scroll_bar_color)
            love.graphics.rectangle("fill", getX(this, c) + wrap_limit -
                                        scroll_bar_width, getY(this, c) +
                                        this.scroll_bar_scale *
                                        this.total_scroll_y, scroll_bar_width,
                                    this.scroll_bar_height)
        end
        love.graphics.setScissor()
    end
end

local function updateScrollableText(this, app)
    local c = makeC(this)
    getY(this, c)
    local font = c(this.font)
    if font ~= this.last_font then
        this.text_obj:setFont(font)
        this.last_font = font
    end
    local text = c(this.coloredtext)
    local wrap_limit = c(this.wrap_limit)
    local view_height = c(this.view_height)
    local num_lines = math.floor(view_height / font:getHeight())
    local text_lines = #text / 2
    this.total_height = (text_lines) * font:getHeight()
    local scroll_delta = c(this.scroll_delta)
    local align = c(this.align)

    if this.last_text ~= text then
        this.scroll_y = 0
        this.total_scroll_y = 0
        this.current_line = 1
        this.scroll_start = true
        this.scroll_end = false
        this.lines = {unpack(text, 1, (num_lines + 2) * 2)}
        this.scroll_bar_height = view_height * view_height / this.total_height --scroll bar height is inversely proportional to the total height
        -- this here is some bullshit i dont understand but it works
        this.scroll_bar_scale = (view_height - font:getHeight() * 2 -
                                    this.scroll_bar_height) /
                                    (this.total_height - view_height +
                                        font:getHeight() * 2)
        this.text_obj:setf(this.lines, wrap_limit, align)
        this.last_text = text
    end

    if text_lines < num_lines then
        this.scroll_start = true
        this.scroll_end = true
    elseif scroll_delta ~= 0 then
        if this.scroll_y + scroll_delta > font:getHeight() then
            this.scroll_start = false
            if this.current_line < text_lines - num_lines + 2 + c(this.extra_lines) then
                this.scroll_y = 0
                this.current_line = this.current_line + 1
            else
                this.scroll_end = true
                this.scroll_y = font:getHeight()
            end
        elseif this.scroll_y + scroll_delta < 0 then
            this.scroll_end = false
            if this.current_line > 1 then
                this.scroll_y = font:getHeight()
                this.current_line = this.current_line - 1
            else
                this.scroll_start = true
                this.scroll_y = 0
            end
        else
            this.scroll_y = this.scroll_y + scroll_delta
        end
        this.start_idx = this.current_line * 2 - 1
        this.end_idx = this.start_idx + (num_lines + 2) * 2
        this.total_scroll_y = (this.current_line - 1) * font:getHeight() +
                                  this.scroll_y
        this.lines = {unpack(text, this.start_idx, this.end_idx)}
        this.text_obj:setf(this.lines, wrap_limit, align)
    end
end

function ScrollableText(coloredtext, font, x, y, wrap_limit, align, view_height,
                        scroll_delta)
    local font = font or love.graphics.getFont()
    return {
        type = "text",
        coloredtext = coloredtext,
        last_text = {},
        lines = {},
        font = font,
        last_font = love.graphics.getFont(),
        text_obj = love.graphics.newText(love.graphics.getFont()),
        start_idx = 1,
        end_idx = 2,
        extra_lines = 0,
        scroll_start = true,
        scroll_end = false,
        scroll_delta = scroll_delta or 0,
        x = x or 0,
        y = y or 0,
        r = 0,
        sx = 1,
        sy = 1,
        kx = 0,
        ky = 0,
        ox = 0,
        oy = 0,
        wrap_limit = wrap_limit or function(this)
            local width = love.graphics.getWidth(screen)
            this.wrap_limit = width
            return width
        end,
        last_wrap_limit = 0,
        view_height = view_height or function(this)
            local height = love.graphics.getHeight(screen)
            this.view_height = height
            return height
        end,
        total_height = 0,
        scroll_y = 0,
        total_scroll_y = 0,
        current_line = 1,
        align = align or "left",
        show_scroll_bar = true,
        scroll_bar_color = {0.66275, 0.66275, 0.66275},
        scroll_bar_width = 5,
        scroll_bar_height = 20,
        scroll_bar_scale = 0,
        render = renderScrollableText,
        update = updateScrollableText,
        p = merge
    }
end
local function renderImage(this, app)
    local c = makeC(this)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.image, getX(this, c), getY(this, c), 0, c(this.sx),
                       c(this.sy))
end

local function updateImage(this, app)
    local c = makeC(this)
    local new_filename = c(this.filename)
    if new_filename ~= this.old_filename then
        this.image = love.graphics.newImage(new_filename)
        this.old_filename = new_filename
    end
end

function Image(filename, x, y, sx, sy)
    return {
        type = "image",
        filename = filename,
        old_filename = "",
        image = love.graphics.newImage(filename),
        x = x or 0,
        y = y or 0,
        sx = sx or 1,
        sy = sy or 1,
        render = renderImage,
        update = updateImage,
        p = merge
    }
end

local function renderAnimation(this, app)
    local c = makeC(this)
    local name = c(this.name)
    if name ~= "" then
        local quad = (this.current_frame - 1) % this.n_quads + 1
        local atlas = math.floor((this.current_frame - 1) / this.n_quads) + 1
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(this.atlases[atlas], this.quads[quad], getX(this, c),
                           getY(this, c), 0, c(this.sx), c(this.sy))
    end

end

local function updateAnimation(this, app, dt)
    local c = makeC(this)
    local name = c(this.name)
    if name ~= this.last_name then
        this:release()
        this.quads = {}
        this.current_frame = 1
        if name and name ~= "" then
            local anim = require("animations." .. name)
            this:p(anim)
            this.current_frame = 1

            for i = 0, anim.rows * anim.cols - 1 do
                this.quads[i + 1] = love.graphics.newQuad(anim.width *
                                                              (i % anim.cols) -
                                                              1, anim.height *
                                                              math.floor(
                                                                  i / anim.cols) -
                                                              1, anim.width,
                                                          anim.height,
                                                          anim.atlas_width,
                                                          anim.atlas_height)
            end
            this.n_quads = #this.quads

            for i = 1, anim.n_atlases do
                this.atlases[i] = love.graphics.newImage(
                                      "animations/" .. name .. "_" ..
                                          tostring(i) .. ".t3x")
            end
        end

        this.last_name = name
    end
    if this.name ~= "" and this.animated then
        this.dt = this.dt + dt
        if #this.durations > 0 and this.dt > this.durations[this.current_frame] /
            1000 then
            this.dt = 0
            if this.current_frame == this.n_frames then
                this.current_frame = 1
            else
                this.current_frame = this.current_frame + 1
            end
        end
    end
end

function Animation(name, x, y, sx, sy, looping)

    return {
        type = "animation",
        name = name,
        last_name = "",
        frame_wait = false,
        atlases = {},
        quads = {},
        n_frames = 0,
        n_atlases = 0,
        n_quads = 0,
        durations = {},
        current_frame = 1,
        dt = 0,
        x = x or 0,
        y = y or 0,
        width = 0,
        height = 0,
        sx = sx or 1,
        sy = sy or 1,
        looping = looping == nil or looping, -- default true
        animated = false,
        render = renderAnimation,
        update = updateAnimation,
        release = function(this)
            for _, atlas in pairs(this.atlases) do
                atlas:release()
                atlas = nil
            end
            this.atlases = {}
            for _, quad in pairs(this.quads) do
                quad:release()
                quad = nil
            end
        end,
        p = merge
    }
end

local function renderButton(this, app)
    c = makeC(this)
    local text = c(this.text)
    local padding = c(this.padding)
    local font = love.graphics.getFont()
    local x = getX(this, c)
    local y = getY(this, c)
    local r = c(this.radius)

    this.rect_width = font:getWidth(this.text_string) + padding * 2 + 7
    this.rect_height = font:getHeight() + padding * 2

    love.graphics.setColor(c(this.background_color))
    love.graphics.rectangle("fill", x, y, this.rect_width, this.rect_height, r,
                            r)
    love.graphics.setCanvas()
    love.graphics.printf(text, x + padding, y + padding, c(this.wrap_limit))
end

local function updateButton(this, app)
    c = makeC(this)
    local x = getX(this, c)
    local y = getY(this, c)
    local text = c(this.text)
    local on_click = c(this.on_click)
    if text ~= this.last_text then
        this.text_string = text
        if type(text) == "table" then
            this.text_string = ""
            for i = 2, #text, 2 do
                this.text_string = this.text_string .. text[i]
            end
        end
        this.last_text = text
    end

    this.is_pressed = app.model.touching and
                          (app.model.touchpos.x > x and app.model.touchpos.x < x +
                              this.rect_width) and
                          (app.model.touchpos.y > y and app.model.touchpos.y < y +
                              this.rect_height)

    if this.is_pressed and not this.was_pressed then
        app:push(unpack(on_click))
    end
    this.was_pressed = this.is_pressed
end

function Button(text, x, y, on_click)
    return {
        type = "button",
        x = x or 0,
        y = y or 0,
        text = text,
        last_text = {},
        text_string = "",
        rect_width = 0,
        rect_height = 0,
        on_click = on_click or function(this) end,
        is_pressed = false,
        was_pressed = false,
        background_color = function(this)
            return this.is_pressed and {0.5, 0.5, 0.5} or {0.8, 0.8, 0.8}
        end,
        padding = 10,
        wrap_limit = function(this)
            local c = makeC(this)
            local width = love.graphics.getWidth(screen) - getX(this, c)
            this.wrap_limit = width
            return width
        end,
        radius = 5,
        render = renderButton,
        update = updateButton,
        p = merge
    }
end
