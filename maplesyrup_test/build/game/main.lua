require("maplesyrup")

topdims = {love.graphics.getDimensions("top")}
bottomdims = {love.graphics.getDimensions("bottom")}

app = initApp({
    topview = {
        Rectangle(0, 0, 0, 0, {0, 0, 0}), {
            {
                Animation(function(this)
                    return "0000" .. tostring(app.model.animIndex + 1)
                end, 30, 30):p({["id"] = "anim0"}), {}
            }, {
                Text({{1, 1, 1}, "henlo world", {0, 0, 1}, "henlo world pt 2"},
                     love.graphics.getFont(), 0, 0, nil, "center"), {}
            }
        }
    },
    bottomview = {
        Rectangle(0, 0, 0, 0), {
            {
                Button("Next Animation", 10, 10, function(this)
                    app.model.animIndex = (app.model.animIndex + 1) % 5
                end), {}
            }
        }
    },
    model = {animIndex = 0}
})

app:update("gamepadpressed", function(model, button)
    if button == "start" then
        love.event.quit()
    elseif button == "a" then
        model.animIndex = (model.animIndex + 1) % 5
    elseif button == "b" then
        if model.sounds["test"] and model.sounds["test"]:isPlaying() then
            app:push("pausesound", "test")
        else
            app:push("playsound", "test")
        end
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

function love.update(dt) app:push("update", dt) end

function love.draw(screen) app:render(screen) end

function love.gamepadpressed(_, button) app:push("gamepadpressed", button) end

function love.gamepadreleased(_, button) app:push("gamepadreleased", button) end
