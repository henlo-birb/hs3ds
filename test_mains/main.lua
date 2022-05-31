function love.draw(screen) 
    love.graphics.print("henlo fren")
end

function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
end