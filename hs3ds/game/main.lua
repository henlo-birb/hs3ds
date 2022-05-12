require("elems")
require("custom_elems")
require("maplesyrup")
require("utils")
require("savedata")


TITLE_LIMIT = 20
topdims = {love.graphics.getDimensions("top")}
bottomdims = {love.graphics.getDimensions("bottom")}
courier = love.graphics.newFont("courier.bcfnt")
default_font = love.graphics.getFont()
topview = {
    Rectangle(0, 0, topdims[1], topdims[2], {0.77647, 0.77647, 0.77647}), {
        {Rectangle(50, function (this) return app.model.getbyid["anim"] and -app.model.getbyid["anim"].scroll_y or 0 end, 
        299, 
        30, 
        {0.933, 0.933, 0.933}), {}}, 
        {
            Text(function(this) return {{0, 0, 0}, app.model.current_page.title} end, 
            courier, 
            function(this) return app.model.current_page.title_len > TITLE_LIMIT and 50 or 0 end, 
            function(this) return 5 - (app.model.getbyid["anim"] and app.model.getbyid["anim"].scroll_y or 0) end, 
            function(this) return app.model.current_page.title_len > TITLE_LIMIT and topdims[1] * .75 or topdims[1] / 2 end, 
            "center"):p({
                sx = function(this) return app.model.current_page.title_len > TITLE_LIMIT and 1 or 2 end,
                sy = function(this) return app.model.current_page.title_len > TITLE_LIMIT and 1 or 2 end }
            ), {}
        }, 
        {
            MultAnimation(function(this)
                local ret = app.model.current_page.media
                if ret[1]:sub(-4) == ".swf" then ret = {} end
                return ret
            end, 50, 30):p({["id"] = "anim"}), {}
        },
        {PopupLabel(10, 10):p({id="popup", background_radius = 5}),{}},
        {SimpleText(function() return "" end, 0,0, {0,0,0}), {}}
    }
}

bottomview = {
    Rectangle(0, 0, bottomdims[1], bottomdims[2], {0.933, 0.933, 0.933}), {
        {
            Button(function(this) return {{0, 0, 0}, "> ", {0, 0, 1}, app.model.next_page.title} end, 
            10, 
            function(this)
                local s = app.model.getbyid["scroll_text"]
                return s and s.y + s.total_height - s.total_scroll_y or 5
            end, 
            function() return {"gotopage", app.model.next_page.page_id} end):p({
                padding = 0, 
                background_color = {0.933, 0.933, 0.933}
            }), {}
        },
        {
            ScrollableText(function(this) return app.model.current_page.content end, 
            courier, 
            10, 
            5, 
            bottomdims[1] * 0.75, 
            "center", 
            bottomdims[2] - 5,
            function(this) return app.model.text_delta_scroll end):p({["id"] = "scroll_text", extra_lines = 3}), {}
        }
    }
}


start_page_id = pcall(require, "pages/" .. Savedata.page_id) and Savedata.page_id  or "0/0/0/1"
start_page = require("pages/" .. start_page_id)
app = initApp({
    topview = topview,
    bottomview = bottomview,
    model = {
        page_id = start_page_id,
        current_page = start_page,
        next_page = require("pages/" .. start_page.next[1]),
        text_delta_scroll = 0,
        image_delta_scroll = 0,
        j = love.joystick.getJoysticks()[1],
    }
})

app:addUpdater("gamepadpressed", function(model, button)
    if button == "start" then
        love.event.quit()
    elseif button == "back" then -- select is "back" for some reason
        Savedata.page_id = model.page_id
        save_savedata()
        model.getbyid["popup"]:display({{0,0,0}, "Game Saved"}, 1.5)
    elseif button == "dpright" then
        if model.current_page.next[1] then
            app:push("gotopage", model.current_page.next[1])
        end
    elseif button == "dpleft" then
        if model.current_page.previous then
            app:push("gotopage", model.current_page.previous)
        end
    elseif button == "dpup" then
        model.text_delta_scroll = -2
    elseif button == "dpdown" then
        model.text_delta_scroll = 2
    elseif button == "leftshoulder" then
        model.getbyid["popup"]:display({{0,0,0},tostring(model.page_id)}, 1.5)
    end

end)

app:addUpdater("gamepadreleased", function(model, button)
    if button == "dpup" or button == "dpdown" then model.text_delta_scroll = 0 end
end)

app:addUpdater("gamepadaxis", function(model, axis)
    _, model.image_delta_scroll = model.j:getAxes()
end)

app:addUpdater("gotopage", function(model, page_id)
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
