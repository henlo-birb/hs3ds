require("utils")
function get(this, a)
    local ret = this[a]
    if type(this[a]) == "function" then
        ret = this[a](this)
    end
    return ret
end

function getX(this)
    local x = this:get("x")
    if this.parent and this.position ~= "absolute" then
        x = x + getX(this.parent)
    end
    return x
end

function getY(this)
    local y = this:get("y")
    if this.parent and this.position ~= "absolute" then
        y = y + getY(this.parent)
    end
    return y
end

local function renderRectangle(this, app)
    love.graphics.setColor(this:get("color"))
    local mode = this:get("mode")
    local x = getX(this)
    local y = getY(this)
    local width = this:get("width")
    local height = this:get("height")
    if mode == "dashed" then
        love.graphics.dashedLine(this:get("dash_length"), this:get("space_length"), 
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
        get = get,
        p = merge
    }
end

local function renderSimpleText(this, app)
    love.graphics.setFont(this:get("font"))
    love.graphics.print({this:get("color"), this:get("text")}, getX(this),
                        getY(this))
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
        get = get,
        p = merge
    }
end

local function renderText(this, app)
    love.graphics.draw(this.text_obj, getX(this), getY(this), this:get("r"),
                       this:get("sx"), this:get("sy"), this:get("ox"), this:get("oy"),
                       this:get("kx"), this:get("ky"))
end

local function updateText(this, app)
    local text = this:get("coloredtext")
    if this.last_text ~= text then
        this.text_obj:setf(text, this:get("wrap_limit"), this:get("align"))
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
        get = get,
        p = merge
    }
end

local function renderScrollableText(this, app)
    local font = this:get("font")
    if font ~= this.last_font then
        this.text_obj:setFont(font)
        this.last_font = font
    end
    local text = this:get("coloredtext")
    local wrap_limit = this:get("wrap_limit")
    local view_height = this:get("view_height")
    local scroll_bar_color = this:get("scroll_bar_color")
    local scroll_bar_width = this:get("scroll_bar_width")
    if #text > 0 then
        love.graphics.setCanvas()
        if not (this.scroll_start and this.scroll_end) and this:get("show_scroll_bar") then
            love.graphics.setColor(scroll_bar_color)
            love.graphics.rectangle("fill",
                                        getX(this) + wrap_limit - scroll_bar_width,
                                        getY(this) + this.scroll_bar_scale * this.total_scroll_y,
                                        scroll_bar_width,
                                    this.scroll_bar_height)
        end
        love.graphics.setCanvas()
        love.graphics.setScissor(getX(this),
                                getY(this) + this.top_scroll,
                                wrap_limit,
                                view_height - this.top_scroll)
        love.graphics.draw(this.text_obj,
                            getX(this),
                            getY(this) - this.scroll_y + this.top_scroll,
                            this:get("r"),
                            this:get("sx"), this:get("sy"),
                            this:get("ox"), this:get("oy"),
                            this:get("kx"),this:get("ky"))
        love.graphics.setScissor()
    end
end

local function updateScrollableText(this, app)
    getY(this)
    local font = this:get("font")
    if font ~= this.last_font then
        this.text_obj:setFont(font)
        this.last_font = font
    end
    local text = this:get("coloredtext")
    local wrap_limit = this:get("wrap_limit")
    local view_height = this:get("view_height")
    local num_lines = math.floor(view_height / font:getHeight())
    local buffer_lines = this:get("buffer_lines")
    local extra_lines = this:get("extra_lines")
    local text_lines = #text / 2 + extra_lines

    local top_space = this:get("top_space")
    this.total_height = top_space + text_lines  * font:getHeight()
    local scroll_delta = this:get("scroll_delta")
    local align = this:get("align")

    if this.last_text ~= text then
        this.scroll_y = 0
        this.total_scroll_y = 0
        this.top_scroll = top_space
        this.current_line = 1
        this.scroll_start = true
        this.scroll_end = false
        this.lines = {unpack(text, 1, (num_lines + buffer_lines) * 2)}
        this.scroll_bar_height = view_height * view_height / (this.total_height + extra_lines * font:getHeight()) --scroll bar height is inversely proportional to the total height
        -- this here is some bullshit i dont understand but it works
        this.scroll_bar_scale = math.abs((view_height - font:getHeight() * buffer_lines - this.scroll_bar_height) /
                                (this.total_height - view_height + font:getHeight() * buffer_lines))
        this.text_obj:setf(this.lines, wrap_limit, align)
        this.last_text = text
    end

    this["half_one"] = getY(this) + this.scroll_bar_scale * this.total_scroll_y

    if text_lines < num_lines then
        this.scroll_start = true
        this.scroll_end = true
    elseif scroll_delta ~= 0 and this:get("visible") ~= false then
        if this.total_scroll_y <= top_space then
            if this.top_scroll - scroll_delta > top_space then
                this.top_scroll = top_space
            elseif this.top_scroll - scroll_delta < 0 then
                this.top_scroll = -0.1
            else
                this.top_scroll = this.top_scroll - scroll_delta
            end
            this.total_scroll_y = top_space - this.top_scroll
        else
            if this.scroll_y + scroll_delta > font:getHeight() then
                this.scroll_start = false
                if this.current_line < text_lines - num_lines + buffer_lines + extra_lines then
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
            this.end_idx = this.start_idx + (num_lines + buffer_lines) * 2
            this.total_scroll_y = (this.current_line - 1) * font:getHeight() +
                                    this.scroll_y + top_space
            this.lines = {unpack(text, this.start_idx, this.end_idx)}
            this.text_obj:setf(this.lines, wrap_limit, align)
        end
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
        buffer_lines = 2,
        scroll_start = true,
        scroll_end = false,
        scroll_delta = scroll_delta or 0,
        top_space = 0,
        top_scroll = 0,
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
        force_scroll = false,
        current_line = 1,
        align = align or "left",
        show_scroll_bar = true,
        scroll_bar_color = {0.66275, 0.66275, 0.66275},
        scroll_bar_width = 5,
        scroll_bar_height = 20,
        scroll_bar_scale = 0,
        render = renderScrollableText,
        update = updateScrollableText,
        get = get,
        p = merge
    }
end
local function renderImage(this, app)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.image, getX(this), getY(this), 0, this:get("sx"),
                       this:get("sy"))
end

local function updateImage(this, app)
    local new_filename = this:get("filename")
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
        get = get,
        p = merge
    }
end

local function renderAnimation(this, app)
    local name = this:get("name")
    if name ~= "" then
        local quad = (this.current_frame - 1) % this.n_quads + 1
        local atlas = math.floor((this.current_frame - 1) / this.n_quads) + 1
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(this.atlases[atlas], this.quads[quad], getX(this),
                           getY(this), 0, this:get("sx"), this:get("sy"))
    end

end

local function updateAnimation(this, app, dt)
    local name = this:get("name")
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
        get = get,
        p = merge
    }
end

local function renderButton(this, app)
    local text = this:get("text")
    local padding = this:get("padding")
    local font = this:get("font")
    local x = getX(this)
    local y = getY(this)
    local r = this:get("radius")

    this.rect_width = font:getWidth(this.text_string) + padding * 2 + 7
    this.rect_height = font:getHeight() + padding * 2

    love.graphics.setColor(this:get("background_color"))
    love.graphics.rectangle("fill", x, y, this.rect_width, this.rect_height, r,
                            r)
    love.graphics.setCanvas()
    love.graphics.setFont(font)
    love.graphics.printf(text, x + padding, y + padding, this:get("wrap_limit"))
end

local function updateButton(this, app)
    local x = getX(this)
    local y = getY(this)
    local text = this:get("text")
    local on_click = this:get("on_click")
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
        font = love.graphics.getFont(),
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
            local width = love.graphics.getWidth(screen) - getX(this)
            this.wrap_limit = width
            return width
        end,
        radius = 5,
        render = renderButton,
        update = updateButton,
        get = get,
        p = merge
    }
end
