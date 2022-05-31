j = love.joystick.getJoysticks()[1]

update1 = function (dt)
    if j:isGamepadDown("a") then
        love.update = update2
        love.draw = draw2
    end
end

update2 = function (dt)
    if j:isGamepadDown("b") then
        love.update = update1
        love.draw = draw1
    end
end

draw1 = function (screen)
    if screen == "bottom" then
        love.graphics.setColor(1,0,1)
        love.graphics.rectangle("fill", 0,0, love.graphics.getWidth("bottom"), love.graphics.getHeight("bottom"))
        love.graphics.setColor(0,0,0)
    end
end

draw2 = function (screen)
    if screen ~= "bottom" then
        love.graphics.setColor(0,1,1)
        love.graphics.rectangle("fill", 0,0, love.graphics.getWidth("left"), love.graphics.getHeight("left"))
        love.graphics.setColor(0,0,0)
    end
end


love.update = update1
love.draw = draw1


function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
end