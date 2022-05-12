function list_to_string(t, sep) 
   sep = sep or " "
   local ret = ""
   for _, v in pairs(t) do 
       ret = v == t[1] and t[1] or ret .. sep .. tostring(v)
   end
   return ret
end

function table_to_string(t)
    local ret = ""
    for k,v in pairs(t) do
      ret = ret .. "\n" .. tostring(k) .. " = " .. (type(v) ~= "table" and tostring(v) or "{ " .. ttostring(v) .. " }")
    end
    return ret
end

function merge(mergeto, mergefrom) 
    for k, v in pairs(mergefrom) do mergeto[k] = v end
    return mergeto
end

function _print(s) 
   love.graphics.print({{0,0,0},s})
end

function point_distance(a, b) 
   return math.sqrt((a[1] - b[1])^2 + (a[2] - b[2])^2)
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

--[[
   Save Table to File
   Load Table from File
   v 1.0
   
   Lua 5.2 compatible
   
   Only Saves Tables, Numbers and Strings
   Insides Table References are saved
   Does not save Userdata, Metatables, Functions and indices of these
   ----------------------------------------------------
   table.save( table , filename )
   
   on failure: returns an error msg
   
   ----------------------------------------------------
   table.load( filename or stringtable )
   
   Loads a table that has been saved via the table.save function
   
   on success: returns a previously saved table
   on failure: returns as second argument an error msg
   ----------------------------------------------------
   
   Licensed under the same terms as Lua itself.
]]--
do
    -- declare local variables
    --// exportstring( string )
    --// returns a "Lua" portable version of the string
    local function exportstring( s )
       return string.format("%q", s)
    end
 
    --// The Save Function
    function table.save(  tbl,filename )
       local charS,charE = "   ","\n"
       local file,err = io.open( filename, "wb" )
       if err then return err end
 
       -- initiate variables for save procedure
       local tables,lookup = { tbl },{ [tbl] = 1 }
       file:write( "return {"..charE )
 
       for idx,t in ipairs( tables ) do
          file:write( "-- Table: {"..idx.."}"..charE )
          file:write( "{"..charE )
          local thandled = {}
 
          for i,v in ipairs( t ) do
             thandled[i] = true
             local stype = type( v )
             -- only handle value
             if stype == "table" then
                if not lookup[v] then
                   table.insert( tables, v )
                   lookup[v] = #tables
                end
                file:write( charS.."{"..lookup[v].."},"..charE )
             elseif stype == "string" then
                file:write(  charS..exportstring( v )..","..charE )
             elseif stype == "number" then
                file:write(  charS..tostring( v )..","..charE )
             end
          end
 
          for i,v in pairs( t ) do
             -- escape handled values
             if (not thandled[i]) then
             
                local str = ""
                local stype = type( i )
                -- handle index
                if stype == "table" then
                   if not lookup[i] then
                      table.insert( tables,i )
                      lookup[i] = #tables
                   end
                   str = charS.."[{"..lookup[i].."}]="
                elseif stype == "string" then
                   str = charS.."["..exportstring( i ).."]="
                elseif stype == "number" then
                   str = charS.."["..tostring( i ).."]="
                end
             
                if str ~= "" then
                   stype = type( v )
                   -- handle value
                   if stype == "table" then
                      if not lookup[v] then
                         table.insert( tables,v )
                         lookup[v] = #tables
                      end
                      file:write( str.."{"..lookup[v].."},"..charE )
                   elseif stype == "string" then
                      file:write( str..exportstring( v )..","..charE )
                   elseif stype == "number" then
                      file:write( str..tostring( v )..","..charE )
                   end
                end
             end
          end
          file:write( "},"..charE )
       end
       file:write( "}" )
       file:close()
    end
    
    --// The Load Function
    function table.load( sfile )
       local ftables,err = loadfile( sfile )
       if err then return _,err end
       local tables = ftables()
       for idx = 1,#tables do
          local tolinki = {}
          for i,v in pairs( tables[idx] ) do
             if type( v ) == "table" then
                tables[idx][i] = tables[v[1]]
             end
             if type( i ) == "table" and tables[i[1]] then
                table.insert( tolinki,{ i,tables[i[1]] } )
             end
          end
          -- link indices
          for _,v in ipairs( tolinki ) do
             tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
          end
       end
       return tables[1]
    end
 -- close do
 end
 
 -- ChillCode