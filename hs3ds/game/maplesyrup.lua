require("elems")
require("utils")

recurseElems = function(f, start_elem, start_parent, ...)
    local function recurse(elem, parent, ...)
        f(elem[1], parent, elem[2], ...)
        for _, child in pairs(elem[2]) do
            -- f(child[1], elem[1], child[2], ...)
            recurse(child, elem[1], ...)
        end
    end
    recurse(start_elem, start_parent, ...)
end

initApp = function(params)
    app = {
        updater = params.updater or newUpdater(),
        model = params.model and merge(newModel(), params.model) or newModel(),
        top_view = params.top_view or newView("top"),
        bottom_view = params.bottom_view or newView("bottom"),
        rendered = {},
        push = function(this, msg, ...)
            for _, func in pairs(this.updater[msg]) do
                func(this.model, ...)
            end
        end,

        addUpdater = function(this, msg, func)
            if this.updater[msg] then
                table.insert(this.updater[msg], func)
            else
                this.updater[msg] = {func}
            end
        end,

        update = function(this, dt)
            local function updateElems(elem, _parent)
                if elem.update then elem:update(this, dt) end
            end
            recurseElems(updateElems, this.top_view)
            recurseElems(updateElems, this.bottom_view)
        end,

        render = function(this, screen)
            if this.model.rendering then
                local id_counter = 1
                local function renderElem(elem)
                    if elem.visible ~= false then
                        elem:render(this)
                    end
                end
                recurseElems(renderElem,
                             screen == "bottom" and this.bottom_view or
                                 this.top_view) -- if drawing bottom screen use bottom view otherwise use top view
                this.rendered[screen] = true
            end
        end
    }

    love.draw = function(screen) app:render(screen) end
    love.update = function(dt) app:update(dt) end
    love.gamepadpressed = function(_, button) app:push("gamepadpressed", button) end
    love.gamepadreleased = function(_, button) app:push("gamepadreleased", button) end
    love.gamepadaxis = function(_, axis, value) app:push("gamepadaxis", axis) end
    love.touchpresssed = function(id, x, y, dx, dy, pressure) app:push("touchpressed", x, y, dx, dy, pressure) end
    love.touchmoved = function(id, x, y, dx, dy, pressure) app:push("touchmoved", x, y, dx, dy, pressure) end
    love.touchreleased = function(id, x, y, dx, dy, pressure) app:push("touchreleased", x, y, dx, dy, pressure) end

    local function initElem(elem, parent, children)
        elem.parent = parent
        local children = {}
        for _, child in pairs(children) do
            table.insert(children, child[1])
        end
        elem.children = children
        if elem.id then
            app.model.getbyid[elem.id] = elem
        end
    end
    recurseElems(initElem, app.top_view)
    recurseElems(initElem, app.bottom_view)
    
    return app
end

newModel = function()
    return {
        touching = false,
        touchpos = {x = 0, y = 0},
        touchdelta = {x = 0, y = 0},
        touchpressure = 0,
        buttonspressed = {},
        t = 0,
        dt = 0,
        sounds = {},
        getbyid = {},
        rendering = true
    }
end

newUpdater = function()
    return {
        ["touchpressed"] = {
            function(model, ...)
                local arg = {...}
                model.touching = true
                model.touchpos = {x = arg[1], y = arg[2]}
                model.touchdelta = {x = arg[3], y = arg[4]}
                model.pressure = arg[5]
            end
        },
        ["touchmoved"] = {
            function(model, ...)
                local arg = {...}
                model.touching = true
                model.touchpos = {x = arg[1], y = arg[2]}
                model.touchdelta = {x = arg[3], y = arg[4]}
                model.pressure = arg[5]
            end
        },
        ["touchreleased"] = {
            function(model, ...)
                local arg = {...}
                model.touching = false
                model.touchpos = {x = arg[1], y = arg[2]}
                model.touchdelta = {x = arg[3], y = arg[4]}
                model.pressure = arg[5]
            end
        },
        ["gamepadpressed"] = {},
        ["gamepadreleased"] = {},
        ["playsound"] = {
            function(model, sound)
                if not model.sounds[sound] then
                    model.sounds[sound] =
                        love.audio.newSource(
                            "audio/" .. sound .. ".mp3", "stream")
                end
                love.audio.play(model.sounds[sound])
            end
        },
        ["pausesound"] = {
            function(model, sound)
                love.audio.pause(model.sounds[sound])
            end
        },
        ["stopsound"] = {
            function(model, sound)
                love.audio.stop(model.sounds[sound])
            end
        }
    }
end

newView = function(screen)
    return {
        Rectangle(0, 
                  0, 
                  love.graphics.getWidth(screen),
                  love.graphics.getHeight(screen),
                  {1, 1, 1}, 
                  "fill"), {}
    }
end

