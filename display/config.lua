-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- dependencies <<<

local require   = require
local display   = require "display"
local math      = require "math"
local string    = require "string"
local io        = require "io"
local os        = require "os"
local debug     = require "debug"
local _G        = require "_G"

-- --------------------------------------------------------------------- >>>

module "display.config"



-- state: display dimensions <<<

--! \var display.config.height_txt
--! \brief Display height in characters / modules.
--! Set via \sa{display.config.setheight}.
height_txt = 0

--! \var display.config.width_txt
--! \brief Display width in characters / modules.
--! Set via \sa{display.config.setwidth}.
width_txt = 0

--! \var display.config.height
--! \brief Display height in pixels.
--! Computed automatically from \sa{display.config.height_txt} on update,
--! assuming a height of 8 pixels per module.
height = 0

--! \var display.config.width
--! \brief Display width in pixels.
--! Computed automatically from \sa{display.config.width_txt} on update,
--! assuming a width of 8 pixels per module.
width = 0

--! \var display.config.vpixels
--! \brief Virtual pixels between lines.
--! Modules inside a single line are placed next to each other.  However, 
--! these lines are not quite adjacent.  This results in non-uniform 
--! distortion of the pixel coordinates.  Although these virual pixels will
--! not be drawn, they can be used to prevent jagged appearance of objects.
--! Important objects should be hand-aligned to ensure they are drawn.
--! Computed automatically from \sa{display.config.width_txt} on update.
vpixels = 0

--! \var display.config.vheight
--! \brief Virtual display height in pixels.
--! Computed automatically from \sa{display.config.height_txt} and
--! \sa{display.config.vpixels} on update, assuming a height of 8 pixels per
--! module.
vheight = 0

-- --------------------------------------------------------------------- >>>

-- dimension change functions <<<

-- do steps necessary for both setheight and setvpixels
local function recompute_dimens( )
    height = height_txt * 8
    vheight = height + vpixels * (height_txt - 1)
end

--! \fn display.config.setheight
--! \brief Set display height in characters / modules.
--! Automatically updates \sa{display.config.height_txt},
--! \sa{display.config.height} and \sa{display.config.vheight}.
--! \param h                        Height in characters.
function setheight( h )
    height_txt = h
    recompute_dimens()
end

--! \fn display.config.setwidth
--! \brief Set display width in characters / modules.
--! Automatically updates \sa{display.config.width_txt} and 
--! \sa{display.config.width}.
--! \param w                        Width in characters.
function setwidth( w )
    width_txt = w
    width = width_txt * 8
end

--! \fn display.config.setvpixels
--! \brief Set the number of virtual (not displayed) pixels between lines.  
--! This is necessary to compensate for the non-uniform distortion resulting 
--! from the space between the lines.
--! Automatically updates \sa{display.config.vpixels} and
--! \sa{display.config.vheight}.
--! \param v                        Number of virtual pixels between lines.
function setvpixels( v )
    vpixels = v
    recompute_dimens()
end

-- --------------------------------------------------------------------- >>>

-- debug helpers <<<

-- all possible modes
local alldebugmodes = "shmpabc"

-- basic debug output function
local do_debug = function(...) io.stderr:write(...) end
local no_debug = function(   )                      end

--! \fn debugline
--! \brief Write debug info together with a stack trace of the location.
--! \param msg                      Warning / error message.
--! \param depth_inc                [optional] Skip more stack levels.
function debugline( msg, depth_inc )
    -- set default
    depth_inc = depth_inc or 0
    -- print message
    debugerr("\n",msg,"\n")
    -- iterate up the stack, printing locations
    for i = 3 + (depth_inc or 0), math.huge do
        local info = debug.getinfo(i,"Sln")
        -- stop when done
        if not info then return end
        -- else output info
        debugerr("    at ", info.short_src,":",info.currentline,
                 " in function ", info.name or "?", "\n")
    end
end
_G.debugline = debugline

-- convert character into numeric escape seqence
local function escapechar( c )
    return string.format("\\%03d", string.byte(c))
end

--! \fn dumpstring
--! \brief Escape a string to be re-read into lua, only using printable 
--! ASCII characters.  Unlike the %q option to string.format, this allows 
--! copying the string from terminal output.
--! In addition to non-printable or non-ASCII characters, backslashes and 
--! both single and double quotes are escaped.
--! The returned string is not enclosed in quotes, add your favourite ones.
--! \param str                      The string.
--! \param force_numeric            If true, escape all numerically.
--! \returns                        Escaped string, without quotes.
function dumpstring( str, force_numeric )
    if force_numeric then
        str = string.gsub(str, "[%z\1-\255]", escapechar)
    else
        -- escape backslashes
        str = string.gsub(str, "\\", "\\\\")
        -- escape single and double quotes
        str = string.gsub(str, "[\"']", "\\%1")
        -- escape control and non-ASCII characters
        str = string.gsub(str, "[\1-\31\127-\255]", escapechar)
        str = string.gsub(str, "%z", "\\000")
    end
    return str
end
_G.dumpstring = dumpstring

-- debug setter
-- assigns _G.debug<kind> and display.config.debug<kind> according to mode
local function setdebugfunction(mode,kind)
    -- function name
    local fname = "debug"..kind
    if string.match(mode,kind) then
        -- enable
        _G[fname], _M[fname] = do_debug, do_debug
    else
        -- disable
        _G[fname], _M[fname] = no_debug, no_debug
    end
end

--! \var display.config.debugmode
--! \brief Select debug messages.
--! Set via \sa{display.config.setdebugmode}.
--! List of all debug modes:
--!   nil   no messages at all
--!   ""    (empty string) only warnings and errors
--!   String contains...
--!     s   Status of packages
--!         ;   sent & received
--!         *   sent & dropped
--!         #   failed (too many retransmits)
--!     h   message Header
--!         "<...>" printable & re-readable string of message header
--!         (escapes non-ASCII-printable characters)
--!     m   Message contents
--!         Also include message contents.
--!     p   Packaging information from buffers.
--!     a   Application use -- level 1.
--!     b   Application use -- level 2.
--!     c   Application use -- level 3.
debugmode = nil

--! \fn display.config.setdebugmode
--! \brief Select debug messages.
--! Re-defines debugging functions to match the debug mode.
--! See \sa{display.config.debugmode} for the full definition of all modes.
--! TODO make dynamically changeable
function setdebugmode(mode)
    debugmode = mode
    if mode then
        -- enable warnings & errors
        _G.debugerr, _M.debugerr = do_debug, do_debug
        -- enable or disable all channels
        for kind in string.gmatch(alldebugmodes,".") do
            setdebugfunction(mode,kind)
        end
    else
        -- disable warnings & errors
        _G.debugerr, _M.debugerr = no_debug, no_debug
        -- disable all channels
        for kind in string.gmatch(alldebugmodes,".") do
            setdebugfunction("",kind)
        end
    end
end

-- fallback (no output)
if not dbg then dbg = function( ) end end



-- --------------------------------------------------------------------- >>>

-- config

-- debug output
--setdebugmode("abchms")              -- activate all / use this for testing
setdebugmode("abchs")              -- 'normal' debugging (no msg content)
--setdebugmode("")                    -- only errors
--setdebugmode(nil)                   -- deactivate completely

-- seed RNG
math.randomseed(os.time())

-- set display dimensions
setwidth(56)                        -- display width in characters
setheight(20)                       -- display height in characters
setvpixels(3)                       -- virtual pixels between lines

-- udp socket parameters
socket_ip       = "172.23.42.120"   -- IP of display
socket_port     = "2342"            -- port for connection
socket_timeout  = 0.4               -- maximum UDP response wait time
socket_retry    = 2                 -- maximum number of retries for sending

bootscreen = 
[[  ,cCCCCCCCCCCCCCCCCCCCCCc,                             ]]..
[[  CC'       `\,    C    `CC                             ]]..
[[  CC          \\   C     CC                             ]]..
[[  CC           `\, \================\, \ \ \            ]]..
[[  CC             \===================\\ \ \ \           ]]..
[[  CC            ,/====================\| |/|/\\         ]]..
[[  CC          ,//  /=================\====/////         ]]..
[[  CC         //    C     CC          .=====/ / /        ]]..
[[  CC,       //     B    ,CC             /-=-/ //        ]]..
[[  `CCCCCCCCCCCCCCCCCCCCCCC'            /  .\|/\/        ]]..
[[                                            X  \        ]]..
[[                                           / \  \____/  ]]..
[[  Willkommen im                           /  |  |       ]]..
[[  Chaos Computer Club Berlin             /   /  |       ]]..
[[                                            |  /        ]]..
[[                                        ----|-`         ]]..
[[                                            |           ]]..
[[                                            \           ]]..
[[                                             \          ]]..
[[  Chaos Twitter: http://twitter.com/chaosknoten         ]]

-- -------------------------------------------------------------------------

return display.config

