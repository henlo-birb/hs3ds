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
            end, 
            function(this) return app.model.anim_scale and 17 or 50 end, 
            function(this) return app.model.anim_scale and 0 or 30 end
        ):p({["id"] = "anim", 
            sx = function(this)return app.model.anim_scale and 1.2 or 1 end, 
            sy = function(this)return app.model.anim_scale and 1.2 or 1 end }), {}
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
                return s and makeC(s)(s.y) + s.total_height - s.total_scroll_y + 10 or 5
            end, 
            function() return {"gotopage", app.model.next_page.page_id} end):p({
                padding = 0, 
                background_color = {0.933, 0.933, 0.933}
            }), {}
        },
        {
            Rectangle(10,
            function(this) 
                local s = app.model.getbyid["scroll_text"]
                return app.model.show_log and s and 5 - s.total_scroll_y or 5
            end, 
            bottomdims[1] * 0.75, 
            function(this) 
                local s = app.model.getbyid["scroll_text"]
                return app.model.show_log and s and s.total_height + 40 - makeC(s)(s.top_space) or 40
            end, {0,0,0}, "dashed"):p({visible = function(this) return app.model.current_page.log_title ~= nil end}), {}
        },
        {
            Button(function(this) 
                    local t = app.model.current_page.log_title 
                    return {{0,0,0}, t and (app.model.show_log and "Hide " or "Show ") .. t .. "  " or ""} end,
                bottomdims[1] / 2 - 100,
                function(this) 
                    local s = app.model.getbyid["scroll_text"]
                    return app.model.show_log and s and 10 - s.total_scroll_y or 10
                end, 
                {"togglelog"}
                ):p({visible = function(this) return app.model.current_page.log_title ~= nil end, font=courier}), {}
        },
        {
            ScrollableText(function(this) return app.model.current_page.content end, 
            courier, 
            function(this) return app.model.current_page.log_title and 20 or 10 end, 
            5, 
            bottomdims[1] * 0.75,
            function(this) return app.model.current_page.log_title and "left" or "center" end, 
            function(this) return bottomdims[2] - makeC(this)(this.y) end,
            function(this) return app.model.text_delta_scroll end
            ):p({
                ["id"] = "scroll_text", 
                extra_lines = 3, 
                visible = function(this) return app.model.current_page.log_title == nil or app.model.show_log end,
                top_space = function(this) return app.model.current_page.log_title and 35 or 0 end
            }), {}
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
        show_log = false,
        anim_scale = false,
        j = love.joystick.getJoysticks()[1],
    }
})

app:addUpdater("togglelog", function(model)
    model.show_log = not model.show_log
end)

app:addUpdater("gamepadpressed", function(model, button)
    if button == "start" then
        love.event.quit()
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
        model.getbyid["popup"]:display({{0,0,0}, model.page_id:gsub("/", ""):match("[^0].+")}, 1.5)
    elseif button == "x" then
        model.anim_scale = not model.anim_scale
    elseif button == "y" then
        Savedata.page_id = model.page_id
        save_savedata()
        model.getbyid["popup"]:display({{0,0,0}, "Game Saved"}, 1.5)
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
    model.show_log = false
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
