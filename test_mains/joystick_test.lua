axis_1 = 0
axis_2 = 0

j = love.joystick.getJoysticks()[1]
function love.update(dt)
    axis_1, axis_2 = j:getAxes()
end

function love.draw(screen)
    if screen ~= "bottom" then
        love.graphics.print("axis 1: "..tostring(axis_1).."\naxis 2: "..tostring(axis_2))
    end
end

function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
end