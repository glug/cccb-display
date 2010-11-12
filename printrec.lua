-- vim: set tw=76 ts=4 et :
-- -------------------------------------------------------------------------

local showkey = function(k)
    if type(k) == "string" then
        return k
    else
        return "["..tostring(k).."]"
    end
end

printrec = function(val, visited, indent, out)
    local rec = out
    visited = visited or {}
    indent = indent or ""
    out = out or {}
    -- helper function
    local w = function(s) table.insert(out,s) end
    -- type case
    local t = type(val)
    if t == "nil" then
        w("nil\n")
    elseif t == "boolean" then
        if val then
            w("true\n")
        else
            w("false\n")
        end
    elseif t == "number" then
        w(tostring(val).."\n")
    elseif t == "string" then
        w(string.format("%q\n",val))
    elseif t == "function" then
        w("<"..(tostring(val))..">\n")
    elseif t == "userdata" then
        w(tostring(val).."\n")
    elseif t == "thread" then
        w("<"..(tostring(val))..">\n")
    elseif t == "table" then
        -- recursive case
        if not visited[val] then
            visited[val] = true
            w("<"..(tostring(val)).."> {\n")
            do
                local indent = indent .. "    "
                    for k, v in pairs(val) do
                        w(indent..(showkey(k)).." = ")
                        printrec(v,visited,indent,out)
                    end
            end
            w(indent.."}\n")
        else
            w("@@<"..(tostring(val))..">\n")
        end
    else
        error "Unhandled type."
    end
    -- output or return
    if rec then
        return out
    else
        io.write(table.concat(out))
    end
end

