-- vim: set tw=76 ts=4 et fdm=marker fmr=<<<,>>> :
-- -------------------------------------------------------------------------

-- dependencies <<<

local require   = require
local display   = require "display"

require "display.config"
require "display.udp"

-- later: client-side fonts, possibly different encodings
--require "display.fonts"

-- --------------------------------------------------------------------- >>>

module "display.graphics"

function makenorm()
    local c = display.config
    local w, h, v = c.width, c.vheight
    c = nil
    return function(x,y)
        x = x/w * 2 -1
        y = y/h * 2 -1
        return x, y
    end
end

-- called for every pixel
-- iteration pattern
-- once per text line: 8 pixels y-wise, to full width
-- then increment offset by 8 + vpixels
function fromfunction(st,f)
    for y = 0, display.config.vheight do
        for x = 0, display.config.width do
            local val = f(x,y)

        end
    end
end

-- TODO

return display.graphics

