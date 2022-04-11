require("maplesyrup")
require("utils")

topdims = {love.graphics.getDimensions("top")}
bottomdims = {love.graphics.getDimensions("bottom")}
courier = love.graphics.newFont("courier.bcfnt")
topview = {
    Rectangle(0, 0, 0, 0, {0, 0, 0}), {
        {
            Animation(function(this)
                return "0000" .. tostring(app.model.anim_index + 1)
            end, 30, 30):p({["id"] = "anim0"}), {}
        },
        {
            Text({
                {1, 1, 1}, "henloworld ", {0, 0, 1}, "henlo world pt 2\n",
                {1, 0, 0}, "i ", {1, 0, 1}, "am ", {0, 1, 0}, "full ",
                {1, 1, 1}, "of ", {1, 1, 0}, "many ", {0.5, 0, 1}, "colors",
                {0, 1, 0.5}, "!!!!!!!!"
            }, courier, 0, 0, nil, "center"), {}
        }
    }
}

bottomview = {
    Rectangle(0, 0, bottomdims[1], bottomdims[2], {1, 1, 1}), {
        {
            ScrollableText(content, courier, 10, 0, bottomdims[1] * .75,
                           "center", bottomdims[2] * .975,
                           function(this)
                return app.model.scroll_y
            end):p({["id"] = "scroll_text"}), {}
        }
    }
}

app = initApp({
    topview = topview,
    bottomview = bottomview,
    model = {anim_index = 0, scroll_y = 0, scrolling = 0}
})

app:update("gamepadpressed", function(model, button)
    if button == "start" then
        love.event.quit()
    elseif button == "a" then
        model.anim_index = (model.animIndex + 1) % 5
    elseif button == "b" then
        if model.sounds["test"] and model.sounds["test"]:isPlaying() then
            app:push("pausesound", "test")
        else
            app:push("playsound", "test")
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

app:update("button")

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
    app:push("update", dt)
    if app.model.scrolling ~= 0 then
        app.model.scroll_y = app.model.getbyid["scroll_text"].last_scroll_y + app.model.scrolling
    end
end

function love.draw(screen) app:render(screen) end

function love.gamepadpressed(_, button) app:push("gamepadpressed", button) end

function love.gamepadreleased(_, button) app:push("gamepadreleased", button) end
