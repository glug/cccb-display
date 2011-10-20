-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- dependencies <<<

require "luarocks.loader"

local require   = require
local display   = require "display"
local socket    = require "socket"
local string    = require "string"
local math      = require "math"
local table     = require "table"

require "display.config"

local type      = type
local ipairs    = ipairs
local tostring  = tostring
local sleep     = sleep
local encode    = display.encode

-- debugging functions
local _debug    = display.config.debugmode
local debugs    = display.config.debugs
local debugh    = display.config.debugh
local debugm    = display.config.debugm
local debugerr  = display.config.debugerr
local debugline = display.config.debugline
local dumpstring= display.config.dumpstring

-- --------------------------------------------------------------------- >>>

module "display.udp"



-- socket creation <<<

--! \var display.udp.sock
--! TODO document this
sock = socket.udp()
sock:setpeername(display.config.socket_ip, display.config.socket_port)
sock:settimeout(display.config.socket_timeout)

-- --------------------------------------------------------------------- >>>

-- Packet format:
--
-- Numbers are encoded in little-endian / network byte order.  Use
-- display.encode(<num>,<lenght>) to encode numbers with a fixed field
-- width.  All display commands have the following structure:
-- {
--   16:    cmd command
--   16:    x   txt:  x position (0..55)
--              OR
--              gfx:  memory offset for raw pixel content (0..(8960-length))
--   16:    y   txt:  y position (0..19)
--              OR
--              gfx:  length of raw pixel content (max. 1450)
--   16:    w   window width (txt: 1..56)
--   16:    h   window height (txt: 1..20)
--  var:    dat data for command (variable length, max.: 1450 due to UDP
--              packet length limit)
--              txt:  codepage 437 encoded text (ASCII + IBM graphic chars)
--              gfx:  series of byte-sized 8-pixel (horizontal) blocks;
--                    highest bit controls leftmost pixel
--              number: automatically encoded in network order, if this is
--                    unwanted, use tostring(...) first.
-- }
--
-- Unneeded packet fields can be filled with anything.  In particular, the
-- data field may be missing (length zero).



-- packet handling <<<

-- convert one or many values into a single string
local function convert_data(...)
    local t = {...}
    -- convert all values
    for k, v in ipairs(t) do
        if type(v) ~= "string" then
            if type(v) == "number" then
                -- binary-encode numbers instead of ASCII-encoding
                t[k] = encode(v)
            else
                t[k] = tostring(v)
            end
        end
    end
    return table.concat(t)
end

--! \fn display.udp.sendcommand
--! \brief Assembles and sends a packet for the display.
--! TODO document this
--! TODO split up?
function sendcommand( cmd, x, y, w, h, data, fill )
    -- set default values
    x = x or 0
    y = y or 0
    w = w or 0
    h = h or 0
    data = data or ""
    -- XXX command specific stuff
    local checkzero = cmd == 0x04   -- write_std MUST be zero terminated
    -- if debugging, warn for any bad command
    if _debug then
        if     cmd == 0x00 then debugline"BAD COMMAND 0x00"
        elseif cmd == 0x01 then debugline"BAD COMMAND 0x01"
        elseif cmd == 0x04 then debugline"OBSOLETE COMMAND 0x04"
        elseif cmd == 0x07 then debugline"BRokEn COMMAND 0x07"
        elseif cmd == 0x0c then debugline"BRokEn COMMAND 0x0c"
        elseif cmd == 0x0e then debugline"BRokEn COMMAND 0x0e"
        elseif cmd == 0x0f then debugline"BRokEn COMMAND 0x0f"
        elseif cmd >  0x12 then debugline"UNDEFINED COMMAND"
        end
    end
    -- handle non-string data, encode numbers instead of tostring'ing
    data = convert_data(data)
    -- if fill is set, repeat data to fill the x-y-w-h rectangle
    if fill then
        local len = (w-x) * (h-y)
        data = string.sub(string.rep(data, math.ceil(len/#data)), 1, len)
    end
    -- check for trailing zero if string must be zero-terminated
    if checkzero and string.byte(data, #data) ~= 0 then
        data = data .. "\0"
    end
    -- check maximum length
    if #data > 1450 then
        debugline("packet too big at "..tostring(#data)
                .." (max: 1450) -- dropped#")
        return nil
    end
    -- convert values
    cmd = encode(cmd,2)
    x   = encode(x,  2)
    y   = encode(y,  2)
    w   = encode(w,  2)
    h   = encode(h,  2)
    -- build header and output debug info
    local header = cmd..x..y..w..h
    debugh('\nout "',dumpstring(header, true))
    debugm(dumpstring(data))
    debugh '"'
    -- send packet
    sock:send(header..data)
    return sock:receive()
end

-- --------------------------------------------------------------------- >>>

-- low-level communication API (direct display commands) <<<

-- These commands supply intermingled default parameters.  Trailing
-- arguments are filled in from different starting positions.
-- The display usually responds with the received packet with the command
-- replaced by ACK.  However, the read_xyz commands change the data field to
-- match the corresponding display state information and reboot does not
-- send a response at all.

-- x00  ACK         -- UNUSED (positive response)
-- x01  NAK         -- UNUSED (negative response)
-- x02  clear       clear screen
function clear(...)         return sendcommand(0x02,...)            end
-- x03  write_raw   put text window at x/y/w/h
function rawtxt(...)        return sendcommand(0x03,...)            end
-- x04  write_std   OBSOLETE  put zero-terminated string at x/y
function write_std(x,y,...) return sendcommand(0x04,x,y,0,0,...)    end
-- x05  lum_raw     put block luminance window at x/y/w/h
function rawlum(...)        return sendcommand(0x05,...)            end
-- x06  set_std_lum OBSOLETE  set luminance for write_std
function set_stdlum(...)    return sendcommand(0x06,0,0,0,0,...)    end
-- x07  setlum      ?BROKEN? XXX (intensity) set luminance of whole screen
function setlum(...)        return sendcommand(0x07,0,0,0,0,...)    end
-- x08  displayreset    re-initialize display and redraw screen content
function displayreset(...)  return sendcommand(0x08,...)            end
-- x09  read_txt    OBSOLETE read display contents [resp. same length as sent packet]
function read_txt(...)      return sendcommand(0x09,0,0,0,0,...)    end
-- x0A  read_lum    OBSOLETE read luminance values [resp. same length as sent packet]
function read_lum(...)      return sendcommand(0x0a,0,0,0,0,...)    end
-- x0B  reboot      reboot display (no response sent)
function reboot(...)        return sendcommand(0x0b,...)            end
-- x0C  allpattern  -- UNUSED
function gfx_allpattern(...)return sendcommand(0x0c,0,0,0,0,...)    end
-- x0D  fadeout     blur and reduce luminance for <n> steps
function fadeout(...)       return sendcommand(0x0d,0,0,0,0,...)    end
-- x0E  gfx_line    -- UNUSED (BROKEN FIXME) send one line of pixel values
-- x0F  gfx_2line   -- UNUSED (BROKEN FIXME) send two lines of pixels
-- x12  gfx_rawput  write continuous pixel block <dat> of length <len> into
--                  the display buffer at offset <off>
function gfx_rawput(off,len,...)return sendcommand(0x12,off,len,0,0,...)end
-- x11  gfx_display re-draw display from buffer (after a block of rawputs)
--function gfx_display(...)   return sendcommand(0x11,...)            end

-- --------------------------------------------------------------------- >>>

-- simple wrappers <<<

-- TODO document this
-- fill screen with some string
function alltxt(...)
    local w, h = display.config.width_txt, display.config.height_txt
    return rawtxt(0,0,w,h,convert_data(...), true)
end

-- TODO document this
-- set luminance for whole screen
function alllum(...)
    local w, h = display.config.width_txt, display.config.height_txt
    return rawlum(0,0,w,h,convert_data(...), true)
end

-- TODO document this
-- split gfx packet as necessary, send multiple packets
function gfx_multiput(off,...)
    local data = convert_data(...)
    for i = 1, #data, 1450 do
        local subdata = string.sub(data,i,i+1449)
        gfx_rawput(off+i-1, #subdata, subdata)
    end
end

-- TODO document this
-- fill a specific line with data
function gfx_line(y,...)
    local len = display.config.width
    local data = convert_data(...)
    data = string.sub(string.rep(data, math.ceil(len/#data)), 1, len)
    gfx_rawput(y*len,len,data)
    gfx_display()
end

-- TODO document this
-- fill whole screen with pattern
function allgfx(...)
    local len = display.config.width * display.config.height_txt
    local data = convert_data(...)
    data = string.sub(string.rep(data, math.ceil(len/#data)), 1, len)
    gfx_multiput(0,data)
    gfx_display()
end

function oldfungfx(f,...)
    local img = {}
    local v1height = display.config.vpixels + 8
    -- iterate over lines
    for ty = 1, display.config.height_txt do
        local line = {}
        -- iterate over bytes in line
        for x = 1, display.config.width do
            -- iterate over bits
            local byte = 0
            for ly = 1, 8 do
                byte = byte*2 + (f(x, (ty-1)*v1height + ly, ...) and 1 or 0)
            end
            table.insert(line, string.char(byte))
        end
        table.insert(img, table.concat(line))
    end
    gfx_multiput(0, table.concat(img))
end

function fungfx(f,...)
    local img = {}
    local v1height = display.config.vpixels + 8
    -- iterate over lines
    for y = 1, display.config.vheight do
        if ((y-1) % v1height) < 8 then
            for x = 1, display.config.width_txt do
                local byte = 0
                for lx = 1, 8 do
                    byte = byte*2 + (f(x*8+lx, y, ...) and 1 or 0)
                end
                table.insert(img, string.char(byte))
            end
        end
    end
    gfx_multiput(0, table.concat(img))
end

function bitmap(t)
    local result = {}
    local e = {}    -- error catcher
    local v1height = display.config.vpixels + 8
    for y = 1, display.config.vheight do
        if ((y-1) % v1height) < 8 then
            for x = 0, display.config.width_txt-1 do
                local byte = 0
                for lx = 1, 8 do
                    byte = byte * 2 + ((t[y] or e)[x*8+lx] and 1 or 0)
                end
                table.insert(result, string.char(byte))
            end
        end
    end
    gfx_multiput(0, table.concat(result))
end

-- --------------------------------------------------------------------- >>>

return display.udp

