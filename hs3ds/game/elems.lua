function addMt(t) 
    local mt = {
        __index = function(_, k)
            local ret = t.data[k]
            if type(ret) == "function"
                then ret = ret(t)
            end
            return ret
        end,
        __newindex = t.data,
        __add = function(_, to)
            merge(t.data, to)
            return t
        end
    }
    setmetatable(t, mt)
    return t
end

function makeElem(data, render, update, methods)
    return addMt(merge({data = data, render = render, update = update}, methods or {}))
end

function getX(this)
    local x = this.x
    if this.parent and this.position ~= "absolute" then
        x = x + getX(this.parent)
    end
    return x
end

function getY(this)
    local y = this.y
    if this.parent and this.position ~= "absolute" then
        y = y + getY(this.parent)
    end
    return y
end

local function renderRectangle(this, app)
    love.graphics.setColor(this.color)
    local x = getX(this)
    local y = getY(this)
    if this.mode == "dashed" then
        love.graphics.dashedLine(this.dash_length, this.space_length, 
        x, y,
        x, y + this.height,
        x + this.width, y + this.height,
        x + this.width, y,
        x, y
    )
    else
        love.graphics.rectangle(this.mode, x, y, this.width, this.height)
    end
    
end

function Rectangle(x, y, width, height, color, mode)
    return makeElem(
    {
        type = "rectangle",
        x = x or 0,
        y = y or 0,
        width = width,
        height = height,
        dash_length = 5,
        space_length = 5,
        color = color or {love.graphics.getBackgroundColor()},
        mode = mode or "fill",
    },
    renderRectangle
    )
end

local function renderSimpleText(this, app)
    love.graphics.setFont(this.font)
    love.graphics.print({this.color, this.text}, getX(this),
                        getY(this))
end

function SimpleText(text, x, y, color, font)
    return makeElem( {
        type = "text",
        x = x or 0,
        y = y or 0,
        text = text,
        color = color or {0, 0, 0},
        font = font or love.graphics.getFont()
        },
    renderSimpleText
    )
end

local function renderText(this, app)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(this.text_obj, getX(this), getY(this), this.r,
                       this.sx, this.sy, this.ox, this.oy,
                       this.kx, this.ky)
end

local function updateText(this, app)
    if this.last_text ~= this.coloredtext then
        this.text_obj:setf(this.coloredtext, this.wrap_limit, this.align)
        this.last_text = this.coloredtext
    end
end

function Text(coloredtext, font, x, y, wrap_limit, align)
    return makeElem( {
        type = "text",
        coloredtext = coloredtext,
        last_text = {},
        text_obj = love.graphics.newText(font),
        font = font or love.graphics.getFont(),
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
        align = align or "left"
    },
    renderText,
    updateText
    )
end

local function renderScrollableText(this, app)
    if this.font ~= this.last_font then
        this.text_obj:setFont(this.font)
        this.last_font = this.font
    end
    if #this.coloredtext > 0 then
        love.graphics.setCanvas()
        if not (this.scroll_start and this.scroll_end) and this.show_scroll_bar then
            love.graphics.setColor(this.scroll_bar_color)
            love.graphics.rectangle("fill",
                                        getX(this) + this.wrap_limit - this.scroll_bar_width,
                                        getY(this) + this.scroll_bar_scale * this.total_scroll_y,
                                        this.scroll_bar_width,
                                    this.scroll_bar_height)
        end
        love.graphics.setCanvas()
        love.graphics.setScissor(getX(this),
                                getY(this) + this.top_scroll,
                                this.wrap_limit,
                                this.view_height - this.top_scroll)
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(this.text_obj,
                            getX(this),
                            getY(this) - this.scroll_y + this.top_scroll,
                            this.r,
                            this.sx, this.sy,
                            this.ox, this.oy,
                            this.kx,this.ky)
        love.graphics.setScissor()
    end
end

local function updateScrollableText(this, app)
    if this.font ~= this.last_font then
        this.text_obj:setFont(this.font)
        this.last_font = this.font
    end
    local num_lines = math.floor(this.view_height / this.font:getHeight())
    local text_lines = #this.coloredtext / 2 + this.extra_lines

    this.total_height = this.top_space + text_lines  * this.font:getHeight()

    if this.last_text ~= this.coloredtext then
        this.scroll_y = 0
        this.total_scroll_y = 0
        this.top_scroll = this.top_space
        this.current_line = 1
        this.scroll_start = true
        this.scroll_end = false
        this.lines = {unpack(this.coloredtext, 1, (num_lines + this.buffer_lines) * 2)}
        this.scroll_bar_height = this.view_height * this.view_height / (this.total_height + this.extra_lines * this.font:getHeight()) --scroll bar height is inversely proportional to the total height
        -- this here is some bullshit i dont understand but it works
        this.scroll_bar_scale = math.abs((this.view_height - this.font:getHeight() * this.buffer_lines - this.scroll_bar_height) /
                                (this.total_height - this.view_height + this.font:getHeight() * this.buffer_lines))
        this.text_obj:setf(this.lines, this.wrap_limit, this.align)
        this.last_text = this.coloredtext
    end

    if text_lines < num_lines then
        this.scroll_start = true
        this.scroll_end = true
    elseif this.scroll_delta ~= 0 and this.visible ~= false then
        if this.total_scroll_y <= this.top_space then
            if this.top_scroll - this.scroll_delta > this.top_space then
                this.top_scroll = this.top_space
            elseif this.top_scroll - this.scroll_delta < 0 then
                this.top_scroll = -0.1
            else
                this.top_scroll = this.top_scroll - this.scroll_delta
            end
            this.total_scroll_y = this.top_space - this.top_scroll
        else
            if this.scroll_y + this.scroll_delta > this.font:getHeight() then
                this.scroll_start = false
                if this.current_line < text_lines - num_lines + this.buffer_lines + this.extra_lines then
                    this.scroll_y = 0
                    this.current_line = this.current_line + 1
                else
                    this.scroll_end = true
                    this.scroll_y = this.font:getHeight()
                end
            elseif this.scroll_y + this.scroll_delta < 0 then
                this.scroll_end = false
                if this.current_line > 1 then
                    this.scroll_y = this.font:getHeight()
                    this.current_line = this.current_line - 1
                else
                    this.scroll_start = true
                    this.scroll_y = 0
                end
            else
                this.scroll_y = this.scroll_y + this.scroll_delta
            end
            this.start_idx = this.current_line * 2 - 1
            this.end_idx = this.start_idx + (num_lines + this.buffer_lines) * 2
            this.total_scroll_y = (this.current_line - 1) * this.font:getHeight() +
                                    this.scroll_y + this.top_space
            this.lines = {unpack(this.coloredtext, this.start_idx, this.end_idx)}
            this.text_obj:setf(this.lines, this.wrap_limit, this.align)
        end
    end 
end

function ScrollableText(coloredtext, font, x, y, wrap_limit, align, view_height, scroll_delta)
    return makeElem({
        type = "text",
        coloredtext = coloredtext,
        last_text = {},
        lines = {},
        font = font or love.graphics.getFont(),
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
    },
    renderScrollableText,
    updateScrollableText
    )
end
local function renderImage(this, app)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.image, getX(this), getY(this), 0, this.sx,
                       this.sy)
end

local function updateImage(this, app)
    if this.filename ~= this.old_filename then
        this.image = love.graphics.newImage(this.filename)
        this.old_filename = this.filename
    end
end

function Image(filename, x, y, sx, sy)
    return makeElem({
        type = "image",
        filename = filename,
        old_filename = "",
        image = love.graphics.newImage(filename),
        x = x or 0,
        y = y or 0,
        sx = sx or 1,
        sy = sy or 1
    },
    renderImage,
    updateImage
    )
end

local function renderAnimation(this, app)
    if this.name ~= "" then
        local quad = (this.current_frame - 1) % this.n_quads + 1
        local atlas = math.floor((this.current_frame - 1) / this.n_quads) + 1
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(this.atlases[atlas], this.quads[quad], getX(this),
                           getY(this), 0, this.sx, this.sy)
    end

end

local function updateAnimation(this, app, dt)
    if this.name ~= this.last_name then
        this:release()
        this.quads = {}
        this.current_frame = 1
        if this.name and this.name ~= "" then
            local anim = require("animations." .. this.name)
            this = this + anim
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
                                      "animations/" .. this.name .. "_" ..
                                          tostring(i) .. ".t3x")
            end
        end

        this.last_name = this.name
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
    return makeElem({
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
        animated = false
    },
    renderAnimation,
    updateAnimation,  {
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
    end,}
    )
end

local function renderButton(this, app)
    this.rect_width = this.font:getWidth(this.text_string) + this.padding * 2 + 7
    this.rect_height = this.font:getHeight() + this.padding * 2

    love.graphics.setColor(this.background_color)
    love.graphics.rectangle("fill", this.x, this.y, this.rect_width, this.rect_height, this.r, this.r)
    love.graphics.setCanvas()
    love.graphics.setFont(this.font)
    love.graphics.printf(this.text, this.x + this.padding, this.y + this.padding, this.wrap_limit)
end

local function updateButton(this, app)
    if this.text ~= this.last_text then
        this.text_string = this.text
        if type(this.text) == "table" then
            this.text_string = ""
            for i = 2, #this.text, 2 do
                this.text_string = this.text_string .. this.text[i]
            end
        end
        this.last_text = this.text
    end

    this.is_pressed = app.model.touching and
                          (app.model.touchpos.x > this.x and app.model.touchpos.x < this.x +
                              this.rect_width) and
                          (app.model.touchpos.y > this.y and app.model.touchpos.y < this.y +
                              this.rect_height)

    if this.is_pressed and not this.was_pressed then
        app:push(unpack(this.on_click))
    end
    this.was_pressed = this.is_pressed
end

function Button(text, x, y, on_click)
    return makeElem({
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
    },
    renderButton,
    updateButton
    )
end

