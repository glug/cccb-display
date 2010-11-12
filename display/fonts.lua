-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- external dependencies <<<

local require   = require
local display   = require "display"

-- --------------------------------------------------------------------- >>>

module "display"

-- load all fonts <<<

require "display.fonts.default"

-- --------------------------------------------------------------------- >>>

-- font dimension helpers <<<

-- TODO document this
function glyphwidth(chr, font)
    font = font or display.fonts.default
    return #font[chr]
end

-- --------------------------------------------------------------------- >>>

return display.fonts

