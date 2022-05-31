points = {}

function point_distance(a, b) 
    return math.sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2)
end

function list_to_string(t, sep) 
    sep = sep or " "
    local ret = ""
    for _, v in pairs(t) do 
        ret = v == t[1] and t[1] or ret .. sep .. tostring(v)
    end
    return ret
end

function love.graphics.dashedLine(dash_length, space_length, x1, y1, x2, y2, ...) 
    local points = {x1, y1, x2, y2, ...}
    for i = 1, #points - 3, 2 do
       local line_length = point_distance({points[i], points[i+1]}, {points[i+2], points[i+3]})
       if line_length <= 2 * dash_length then
          love.graphics.line(points[i], points[i+1], points[i+2], points[i+3])
       else
          local num_dashes = math.floor((line_length - dash_length) /  (dash_length + space_length)) + 1
          local real_space_length = (line_length - (dash_length * num_dashes)) / (num_dashes - 1)

          --unit vector for current segment
          local v_x = (points[i+2] - points[i]) / line_length
          local v_y = (points[i+3] - points[i+1]) / line_length

          for j = 1, num_dashes do
             local x = points[i] + v_x * (j-1) * (dash_length + (j ~= 1 and real_space_length or 0))
             local y = points[i+1] + v_y * (j-1) * (dash_length + (j ~= 1 and real_space_length or 0))
             love.graphics.line(x, y, x + v_x * dash_length, y + v_y * dash_length)
          end
       end
       
    end
 end

function love.touchpressed(_, x, y) 
    table.insert(points, x)
    table.insert(points, y)
end

function love.draw(screen) 
    if screen == "bottom" then
        love.graphics.setColor({1,1,1})
        love.graphics.dashedLine(5, 5, unpack(points))
    end
end

function love.gamepadpressed(_, button) 
    if button == "start" then
        love.event.quit()
    end
end