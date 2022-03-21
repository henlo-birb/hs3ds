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
    love.graphics.setFont(c(this.font))
    love.graphics.printf(c(this.coloredtext), getX(this, c), getY(this, c),
                         c(this.limit), c(this.align))
end

function Text(coloredtext, font, x, y, limit, align)
    local font = font or love.graphics.getFont()
    return {
        type = "text",
        coloredtext = coloredtext,
        font = font,
        x = x or 0,
        y = y or 0,
        limit = limit or function()
            local width = love.graphics.getWidth(screen);
            limit = width;
            return width
        end,
        align = align or "left",
        render = renderText,
        p = merge
    }
end

local function renderImage(this, app)
    local c = makeC(this)
    local newFilename = c(this.filename)
    if newFilename ~= this.oldFilename then
        this.image = love.graphics.newImage(newFilename)
        this.oldFilename = newFilename
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.image, getX(this, c), getY(this, c), 0, c(this.sx),
                       c(this.sy))
end

function Image(filename, x, y, sx, sy)
    return {
        type = "image",
        filename = filename,
        oldFilename = "",
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
    local newName = c(this.name)
    if newName ~= this.oldName then
        for _, atlas in pairs(this.atlases) do
            atlas:release()
            atlas = nil
        end
        this.atlases = {}
        for _, quad in pairs(this.quads) do
            quad:release()
            quad = nil
        end

        local anim = require("animations." .. newName)
        this:p(anim)
        this.currentFrame = 1

        this.quads = {}
        for i = 0, anim.rows * anim.cols - 1 do
            this.quads[i + 1] = love.graphics.newQuad(anim.width *
                                                          (i % anim.cols) - 1,
                                                      anim.height *
                                                          math.floor(
                                                              i / anim.cols) - 1,
                                                      anim.width, anim.height,
                                                      anim.atlasWidth,
                                                      anim.atlasHeight)
        end
        this.nQuads = #this.quads

        for i = 1, anim.nAtlases do
            this.atlases[i] = love.graphics.newImage(
                                  "animations/" .. newName .. "_" .. tostring(i) ..
                                      ".t3x")
        end
        this.oldName = newName
    end

    local quad = (this.currentFrame - 1) % this.nQuads + 1
    local atlas = math.floor((this.currentFrame - 1) / this.nQuads) + 1
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(this.atlases[atlas], this.quads[quad], getX(this, c),
                       getY(this, c), 0, c(this.sx), c(this.sy))

end

function Animation(name, x, y, sx, sy, looping)

    return {
        type = "animation",
        name = name,
        oldName = "",
        framewait = false,
        atlasdata = {},
        atlases = {},
        quads = {},
        currentFrame = 1,
        framesPerAtlas = 0,
        dt = 0,
        nFrames = 0,
        nAtlases = 0,
        nQuads = 0,
        durations = {},
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

    this.isPressed = app.model.touching and
                         (app.model.touchpos.x > x and app.model.touchpos.x < x +
                             rectWidth) and
                         (app.model.touchpos.y > y and app.model.touchpos.y < y +
                             rectHeight)

    if this.isPressed and not this.wasPressed then this:onClick() end
    this.wasPressed = this.isPressed

    love.graphics.setColor(c(this.backgroundColor))
    love.graphics.rectangle("fill", x, y, rectWidth, rectHeight, r, r)
    love.graphics.print({c(this.textColor), c(this.text)}, x + padding,
                        y + padding)
end
function Button(text, x, y, onClick)
    return {
        type = "button",
        x = x or 0,
        y = y or 0,
        text = text,
        onClick = onClick or function(this) end,
        isPressed = false,
        wasPressed = false,
        backgroundColor = function(this)
            return this.isPressed and {0.5, 0.5, 0.5} or {0.8, 0.8, 0.8}
        end,
        padding = 10,
        radius = 5,
        textColor = {0, 0, 0},
        render = renderButton,
        p = merge
    }
end
