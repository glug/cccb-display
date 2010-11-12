-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- external dependencies <<<

local require   = require
local math      = require "math"
local string    = require "string"

-- TODO split these up
require "helpers"

-- --------------------------------------------------------------------- >>>

module "display"



-- encoding helpers <<<

--! \fn display.bytesplit
--! \brief Split a natural number into bytes, lowest byte first.
--! Handles neither negative numbers nor fractional parts.
--! \param x[in]                    The number.
--! \return                         List of byte values as numbers.
--!
--! \example bytesplit(123) --> 123
--! \example bytesplit(12345) --> 57, 48
--! \example bytesplit(12345.6) --> 57.6, 48    -- (!) 
--! \example bytesplit(0) -->                   -- (!) <implicit nil>
--! \example bytesplit(-1) -->                  -- (!) <implicit nil>
function bytesplit( x )
    if x <= 0
        then return
        else return math.fmod(x,256),
                    bytesplit(math.floor(x/256))
    end
end

--! \fn display.encode
--! \brief Encode a natural number as a network byte order string.
--! The restrictions from \sa{display.bytesplit} apply here as well.
--! \param x[in]                    The number.
--! \param len[in]                  [optional] Forced length of result.
--! \return                         Network-order encoded string of number.
--!
--! \example encode(0) --> "\0"
--! \example encode(12345) --> "\57\48"
--! \example encode(12345,4) --> "\57\48\0\0"
--! \example encode(12345,1) --> "\57"
function encode( x, len )
    local bytes = string.char(bytesplit(x))
    -- remove entries if too many
    if len then bytes = string.sub(bytes,1,len) end
    -- pad with zeroes, also output at least one zero
    len = len or 1
    bytes = bytes .. string.rep("\0", len - #bytes)
    return bytes
end

-- --------------------------------------------------------------------- >>>

-- load sub-packages <<<

require "display.config"            -- config, constants and debug stuff
require "display.udp"               -- low-level UDP interface
require "display.text"              -- higher level text interface
require "display.graphics"          -- higher level graphics interface

-- --------------------------------------------------------------------- >>>

return _M

-- subsection_template <<<
-- --------------------------------------------------------------------- >>>

