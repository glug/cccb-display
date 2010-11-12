-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- no module => no deps



-- no module here, put into _G



-- XXX clean XXX this XXX shit XXX  up  XXX

-- call sleep executable, returning the return value
-- XXX "while sleep(X) == 0 do ... end" will break out of the loop on ^C
function sleep( s ) return os.execute("sleep "..s) end


-- XXX fix printrec module : return the function
require "printrec"



function limitrange( range_min, range_max )
    local min, max = math.min, math.max
    return function(x)
        return min(range_max, max(range_min, x))
    end
end



-- explode one level of the string
-- width of zero forces reduction to first subtable
local function explode_every( width, f_cont )
    -- default is to save substrings unchanged
    if not f_cont then f_cont = function( x ) return x end end
    if width == 0 then
        -- force removal of superfluous content and 1-entry top layers
        return function( str )
            local t = f_cont(str)[1]
            while type(t) == "table" and #t == 1 do
                t = t[1]
            end
            return t or ""
        end
    else
        -- split into sub-tables
        return function( str )
            -- collect all results of sub-string processing
            local t = {}
            for pos = 0, #str, width do
                local m = string.sub(str, pos+1, pos+width)
                if m == "" then
                    break
                else
                    -- pass into continuation and save the result
                    local substr = string.sub(str,pos+1,pos+width)
                    table.insert(t,(f_cont(substr)))
                end
            end
            return t
        end
    end
end

--! \fn string.explode
--! \brief Split a string into a multi-dimensional table.
--! \param str[in]                  String to be split.
--! \param ...                      lengths of sub-dimensions, a zero forces
--!                                 removal of all higher dimensions.
--! \return            ...#1 == 0)  nil
--!                    ...#2 == 0)  string
--!                             *)  table of split string
--!
--! \example string.explode("1234") --> {'1', '2', '3', '4'}
--! \example string.explode("1234",2) --> {'12', '34'}
--! \example string.explode("1234",1,2) --> { {'1', '2'}, {'3', '4'} }
--! \example string.explode("1234",1,2,0) --> {'1', '2'}
--! \example string.explode("1234",1,2,2) --> { { {'1', '2'}, {'3', '4'} } }
--! \example string.explode("1234",1,2,2,0) --> { {'1', '2'}, {'3', '4'} }
function string.explode( str, ... )
    -- collect sub-dimensions
    local t = {...}
    -- no entry means default of 1 character
    t[1] = t[1] or 1
    -- build splitting function
    local splitfun = nil
    local width_factor = 1
    for k,v in ipairs(t) do
        width_factor = width_factor * v
        splitfun = explode_every(width_factor, splitfun)
    end
    -- return result
    return splitfun(str)
end



--! \fn table.depth
--! \brief Determine depth of a table.
--! \param t[in]                    The table.
--! \param balanced[in,optional]    Assume the table is fully balanced. 
--!                                 (Much faster for large tables.)
--! \return                         Depth as number.
--!
--! \example table.depth({1,2,3}) --> 1
--! \example table.depth({{},{{}}}) --> 3
--! \example table.depth({{},{{}}},true) -->  2  OR  3  (!!!)
function table.depth( t, balanced )
    if type(t) == "table" then
        local d = 0
        for k, v in pairs(t) do
            local dsub = table.depth(v, balanced)
            if dsub > d then d = dsub end
            if balanced then break end -- assume same depth everywhere
        end
        return d+1
    else
        return 0
    end
end

--! \fn table.zipWith
--! \brief Zip the numeric fields of two tables
--! \param f[in]                    Combining function.
--! \param t[in]                    First table.
--! \param u[in]                    Second table.
function table.zipWith( f, t, u )
    local ret = {}
    -- optional zero entry as special case
    if t[0] or u[0] then
        ret[0] = f(t[0], u[0])
    end
    -- iterate while either one exists
    for i = 1, math.huge do
        local x, y = t[i], u[i]
        if x or y then
            ret[i] = f(x,y)
        else
            break
        end
    end
    -- done
    return ret
end

--! \fn table.minFieldLengths  XXX  FIXME
--! \brief Determine widths of each level for serialization.
--! \param t[in]                    The table.
--! \return                         Widths per level as table of numbers.
function table.minFieldLengths( t )
    local ttype = type(t)
    if ttype == "table" then
        -- determine widths of every element, find maximum
        local max = {}
        local function max(x,y)
            x = x or 0
            y = y or 0
            return math.max(x,y)
        end
        for k, v in pairs(t) do
            max = table.zipWith(max,table.minFieldLengths(v))
        end
        max[#max+1] = max[#max]*#t
        return max
    elseif ttype == "string" then
        -- length of string
        return {#t}
    else -- default: length of tostring of value
        return {#(tostring(t))}
    end
end

-- implodes one level, lower levels are handled by f_cont.
-- \example implode_below(1){'a','b','c'} --> "abc"
local function implode_below( width, f_cont )
    -- default action is to barf
    local f_cont = f_cont or function() end
    return function( t )
        if type(t) == "table" then
            -- iterate over subvalues
            local tstr = {}
            for k, v in ipairs(t) do
                local vstr = f_cont(v)
                -- bad value -- stop and return nothing
                if not vstr then return end
                -- add to output
                table.insert(tstr,vstr)
            end
            t = table.concat(tstr)
        else
            -- simple string conversion
            t = tostring(t)
        end
        -- do padding if known width
        if width then
            local len = width - #t
            if len > 0 then
                t = t..string.rep(' ',len)
            end
        end
        -- return resulting string
        return t
    end
end



--! \fn table.implode
--! \brief Convert nested table of simple values into a single string.
--! \param t[in]                    The table.
--! \param lengths[in]              Table of per-level lengths, lowest level 
--!                                 first. If unspecified, no padding will 
--!                                 be done.
--! \param depth[in]                Depth of the table.  If unspecified, the 
--!                                 depth will be computed under the 
--!                                 assumption that the table is balanced.
--! \return                         The resulting string.
function table.implode( t, lengths, depth )
    -- check defaults
    lengths = lengths or {}
    depth = depth or table.depth(t, true)
    -- compose imploder
    local implodefun = nil
    local width_factor = 1
    for i = 1, depth+1 do
        -- compute new field length if set
        local width = lengths[i]
        if width then
            width_factor = width_factor*width
            width = width_factor
        end
        implodefun = implode_below(width, implodefun)
    end
    -- compute result
    return implodefun(t)
end





return true

