function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
end