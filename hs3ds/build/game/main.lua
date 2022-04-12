require("maplesyrup")
require("utils")

topdims = {love.graphics.getDimensions("top")}
bottomdims = {love.graphics.getDimensions("bottom")}
courier = love.graphics.newFont("courier.bcfnt")
default_font = love.graphics.getFont()
topview = {
    Rectangle(0, 0, topdims[1], topdims[2], {0.776, 0.776, 0.776}), {
        {
            Rectangle(30, 0, 325, 30, {0.933, 0.933, 0.933}), {}
        } 
        ,{
            Text(function (this)
                return {{0,0,0}, app.model.current_page.title}
            end, courier, 0, 5, topdims[1] / 2, "center"):p({sx = 2, sy = 2}), {}
        }
        ,{
            Animation(function(this)
                local ret = app.model.current_page.media[1]
                if ret:sub(-4) == ".swf" then ret = "" end
                return ret
            end, 30, 30):p({["id"] = "anim"}), {}
        }
    }
}

bottomview = {
    Rectangle(0, 0, bottomdims[1], bottomdims[2], {0.933, 0.933, 0.933}), {
        {
            ScrollableText(function(this)
                return app.model.current_page.content
            end, courier, 10, 5, bottomdims[1] * 0.75, "center",
                           bottomdims[2] * 0.8,
                           function(this) return app.model.scroll_y end):p({
                ["id"] = "scroll_text"
            }), {}
        }, 
        {
            Button(function (this)
                return {{0,0,0}, "> ", {0,0,1}, app.model.next_page.title}
            end, 10, bottomdims[2] - 40, function ()
                app:push("gotopage", app.model.next_page.page_id)
            end):p({padding = 0, background_color = {0.933, 0.933, 0.933}}), {}
        }
    }
}

app = initApp({
    topview = topview,
    bottomview = bottomview,
    model = {
        page_id = 1,
        current_page = require("pages.1"),
        next_page = require("pages.2"),
        scroll_y = 0,
        scrolling = 0
    }
})

app:update("gamepadpressed", function(model, button)
    if button == "start" then
        love.event.quit()
    elseif button == "a" or button == "dpright" then
        if model.current_page.next[1] then
            app:push("gotopage", model.next_page.page_id)
        end
    elseif button == "b" or button == "dpleft" then
        if model.current_page.previous then
            app:push("gotopage", model.current_page.previous)
        end
    elseif button == "dpup" then
        model.scrolling = -2
    elseif button == "dpdown" then
        model.scrolling = 2
    end
end)

app:update("gamepadreleased", function(model, button)
    if button == "dpup" or button == "dpdown" then model.scrolling = 0 end
end)

app:update("gotopage", function(model, page_id)
    model.page_id = page_id
    if page_id == model.current_page.next[1] then
        model.current_page = model.next_page
        model.next_page = require("pages." .. model.current_page.next[1])
    elseif page_id == model.current_page.previous then
        model.next_page = model.current_page
        model.current_page = require("pages." .. model.next_page.previous)
    else
        model.current_page = require("pages." .. page_id)
        model.next_page = require("pages." .. model.current_page.next[1])
    end
end)

function love.touchpressed(id, x, y, dx, dy, pressure)
    app:push("touchpressed", x, y, dx, dy, pressure)
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    app:push("touchmoved", x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    app:push("touchreleased", x, y, dx, dy, pressure)
end

function love.update(dt)
    app:push("updateanimations", dt)
    if app.model.scrolling ~= 0 then
        app.model.scroll_y = app.model.getbyid["scroll_text"].last_scroll_y +
                                 app.model.scrolling
    end
end

function love.draw(screen) app:render(screen) end

function love.gamepadpressed(_, button) app:push("gamepadpressed", button) end

function love.gamepadreleased(_, button) app:push("gamepadreleased", button) end
