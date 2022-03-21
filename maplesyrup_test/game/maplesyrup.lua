require("elems")
require("utils")
initApp = function(params)

    return {
        updater = params.updater or newUpdater(),
        model = params.model and merge(newModel(), params.model) or newModel(),
        topview = params.topview or newView("top"),
        bottomview = params.bottomview or newView("bottom"),
        rendered = false,
        push = function(this, msg, ...)
            for _, func in pairs(this.updater[msg]) do
                func(this.model, ...)
            end
        end,

        update = function(this, msg, func)
            if this.updater[msg] then
                table.insert(this.updater[msg], func)
            else
                this.updater[msg] = {func}
            end
        end,

        render = function(this, screen)
            local function recurse(elem, parent)
                if not this.rendered then -- do per-element related initializations on first render since we're looping through em all for free
                    elem[1].parent = parent
                    if elem[1].type == "animation" then
                        table.insert(this.model.animations, elem[1])
                    end
                    if elem[1].id then
                        this.model.getbyid[elem[1].id] = elem[1]
                    end
                end

                elem[1]:render(this)
                for _, child in pairs(elem[2]) do
                    recurse(child, elem[1])
                end
            end
            recurse(screen == "bottom" and this.bottomview or this.topview) -- if drawing bottom screen use bottom view otherwise use top view
            this.rendered = true
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
        getbyid = {}
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
                    model.sounds[sound] = love.audio.newSource("audio/"..sound..".mp3", "stream")
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
        },
        ["update"] = {
            function(model, dt)
                model.t = model.t + dt
                model.dt = dt
                for _, anim in pairs(model.animations) do
                    anim.dt = anim.dt + dt
                    if anim.dt > anim.durations[anim.current_frame] / 1000 then
                        anim.dt = 0
                        if anim.current_frame == anim.n_frames then
                            anim.current_frame = 1
                        else
                            anim.current_frame = anim.current_frame + 1
                        end
                    end
                end
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

