require("utils")
local function makeC(this)
    return function(a)
        ret = a
        if type(a) == "function" then ret = a(this) end
        return ret
    end
end

local function getX(this, c)
    local x = c(this.x)
    if this.parent and this.position ~= "absolute" then
        x = x + getX(this.parent, makeC(this.parent))
    end
    return x
end

local function getY(this, c)
    local y = c(this.y)
    if this.parent and this.position ~= "absolute" then
        y = y + getY(this.parent, makeC(this.parent))
    end
    return y
end

local function renderRectangle(this, app)
    local c = makeC(this)
    love.graphics.setColor(c(this.color))
    love.graphics.rectangle(c(this.mode), getX(this, c), getY(this, c),
                            c(this.width), c(this.height))
end

function Rectangle(x, y, width, height, color, mode)
    return {
        type = "rectangle",
        x = x or 0,
        y = y or 0,
        width = width,
        height = height,
        color = color or {love.graphics.getbackground_color()},
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
    local text = c(this.coloredtext)
    if this.last_text ~= text then
        this.text_obj:setf(text, c(this.wrap_limit), c(this.align))
        this.last_text = text
    end
    love.graphics.draw(this.text_obj, getX(this, c), getY(this, c), c(this.r),
                       c(this.sx), c(this.sy), c(this.ox), c(this.oy),
                       c(this.kx), c(this.ky))
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
    local num_lines = math.floor(view_height / font:getHeight())

    local scroll_y = c(this.scroll_y)
    local align = c(this.align)

    if this.last_text ~= text then
        scroll_y = 0
        this.current_line = 1
        this.lines = {unpack(text, 1, (num_lines - 1) * 2)}
        this.text_obj:setf(this.lines, wrap_limit, align)
        this.last_text = text
    end

    if scroll_y ~= this.last_scroll_y then
        if scroll_y > font:getHeight() then
            if this.current_line < #text - (num_lines - 2) * 2 then
                scroll_y = scroll_y - font:getHeight()
                this.current_line = this.current_line + 2
                this.lines = {
                    unpack(text, this.current_line,
                           this.current_line + (num_lines - 1) * 2)
                }
                this.text_obj:setf(this.lines, wrap_limit, align)
            else
                scroll_y = this.last_scroll_y
            end
        elseif scroll_y < 0 then
            if this.current_line > 2 then
                scroll_y = scroll_y + font:getHeight()
                this.current_line = this.current_line - 2
                this.lines = {
                    unpack(text, this.current_line,
                           this.current_line + (num_lines - 1) * 2)
                }
                this.text_obj:setf(this.lines, wrap_limit, align)
            else
                scroll_y = this.last_scroll_y
            end
        end

        this.last_scroll_y = scroll_y
    end

    love.graphics.setCanvas()
    love.graphics.setScissor(getX(this, c), getY(this, c), wrap_limit,
                             view_height)
    love.graphics.draw(this.text_obj, getX(this, c), getY(this, c) - scroll_y,
                       c(this.r), c(this.sx), c(this.sy), c(this.ox),
                       c(this.oy), c(this.kx), c(this.ky))
    love.graphics.setScissor()
end

function ScrollableText(coloredtext, font, x, y, wrap_limit, align, view_height,
                        scroll_y)
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
        scroll_y = scroll_y or 0,
        last_scroll_y = -1,
        current_line = 1,
        align = align or "left",
        render = renderScrollableText,
        p = merge
    }
end
local function renderImage(this, app)
    local c = makeC(this)
    local new_filename = c(this.filename)
    if new_filename ~= this.old_filename then
        this.image = love.graphics.newImage(new_filename)
        this.old_filename = new_filename
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.image, getX(this, c), getY(this, c), 0, c(this.sx),
                       c(this.sy))
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
        p = merge
    }
end

local function renderAnimation(this, app)
    local c = makeC(this)
    local name = c(this.name)
    if name ~= this.last_name then
        for _, atlas in pairs(this.atlases) do
            atlas:release()
            atlas = nil
        end
        this.atlases = {}
        for _, quad in pairs(this.quads) do
            quad:release()
            quad = nil
        end
        this.quads = {}
        this.current_frame = 1
        if name then
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

    if name ~= "" then
        local quad = (this.current_frame - 1) % this.n_quads + 1
        local atlas = math.floor((this.current_frame - 1) / this.n_quads) + 1
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(this.atlases[atlas], this.quads[quad], getX(this, c),
                           getY(this, c), 0, c(this.sx), c(this.sy))
    end

end

function Animation(name, x, y, sx, sy, looping)

    return {
        type = "animation",
        name = name,
        last_name = "",
        frame_wait = false,
        atlas_data = {},
        atlases = {},
        quads = {},
        n_atlases = 0,
        n_quads = 0,
        durations = {},
        dt = 0,
        x = x or 0,
        y = y or 0,
        sx = sx or 1,
        sy = sy or 1,
        looping = looping == nil or looping, -- default true
        render = renderAnimation,
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
    local rectWidth = font:getWidth(text) + padding * 2 + 7
    local rectHeight = font:getHeight() + padding * 2

    this.is_pressed = app.model.touching and
                         (app.model.touchpos.x > x and app.model.touchpos.x < x +
                             rectWidth) and
                         (app.model.touchpos.y > y and app.model.touchpos.y < y +
                             rectHeight)

    if this.is_pressed and not this.was_pressed then this:on_click() end
    this.was_pressed = this.is_pressed

    love.graphics.setColor(c(this.background_color))
    love.graphics.rectangle("fill", x, y, rectWidth, rectHeight, r, r)
    love.graphics.print({c(this.textColor), c(this.text)}, x + padding,
                        y + padding)
end
function Button(text, x, y, on_click)
    return {
        type = "button",
        x = x or 0,
        y = y or 0,
        text = text,
        on_click = on_click or function(this) end,
        is_pressed = false,
        was_pressed = false,
        background_color = function(this)
            return this.is_pressed and {0.5, 0.5, 0.5} or {0.8, 0.8, 0.8}
        end,
        padding = 10,
        radius = 5,
        textColor = {0, 0, 0},
        render = renderButton,
        p = merge
    }
end
