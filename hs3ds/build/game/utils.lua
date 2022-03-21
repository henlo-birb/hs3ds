json = require("json")
local f = love.filesystem.newFile("animations.json")
f:open("r")
local raw = f:read()
f:close()
AnimationData = json.decode(raw)

function ttostring(t)
    local ret = ""
    for k,v in pairs(t) do
        ret = ret .. "\n" .. tostring(k) .. " = " .. tostring(v)
    end
    return ret
end

function merge(mergeto, mergefrom) 
    for k, v in pairs(mergefrom) do mergeto[k] = v end
    return mergeto
end