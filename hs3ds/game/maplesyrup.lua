require("elems")
require("utils")

recurseElems = function(f, start_elem, start_parent, ...)
    local function recurse(elem, parent, ...)
        f(elem[1], parent, ...)
        for _, child in pairs(elem[2]) do
            f(child[1], elem[1], ...)
            recurse(child, elem[1], ...)
        end
    end
    recurse(start_elem, start_parent, ...)
end

initApp = function(params)
    return {
        updater = params.updater or newUpdater(),
        model = params.model and merge(newModel(), params.model) or newModel(),
        topview = params.topview or newView("top"),
        bottomview = params.bottomview or newView("bottom"),
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
            recurseElems(updateElems, this.topview)
            recurseElems(updateElems, this.bottomview)
        end,

        render = function(this, screen)
            if this.model.rendering then
                local function renderElem(elem, parent)
                    if not this.rendered[screen] then -- do per-element related initializations on first render since we're looping through em all for free
                        elem.parent = parent
                        if elem.type == "animation" then
                            table.insert(this.model.animations, elem)
                        end
                        if elem.id then
                            this.model.getbyid[elem.id] = elem
                        end
                    end
                    elem:render(this)
                end
                recurseElems(renderElem,
                             screen == "bottom" and this.bottomview or
                                 this.topview) -- if drawing bottom screen use bottom view otherwise use top view
                this.rendered[screen] = true
            end
        end
    }
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
        animations = {},
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
        Rectangle(0, 0, love.graphics.getWidth(screen),
                  love.graphics.getHeight(screen), {1, 1, 1}, "fill"), {}
    }
end

