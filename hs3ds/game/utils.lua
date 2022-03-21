

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