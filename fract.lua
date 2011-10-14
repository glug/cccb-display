#!/usr/bin/lua
-- vim: set tw=76 ts=4 et :
-- -------------------------------------------------------------------------

require "display"

do
    local rx = display.config.width
    local ry = display.config.vheight
    function coordinates(lx,ly,w,h)
        local w = w or rx/ry
        local h = h or 1
        local lx = lx or 0
        local ly = ly or 0

        local xr2 = rx/2
        local yr2 = ry/2

        local cmap = function(x,y)
            return (x-xr2)/xr2*w+lx, (y-yr2)/yr2*h+ly
        end

        cunmap = function(x,y)
            return ((x-lx)/w/aspect*xr2)+xr2, ((y-ly)/h*yr2)+yr2
        end

        return cmap, cunmap
    end
end

-- -------------------------------------------------------------------------
-- mandelbrot fractal

function modcolor(n)
    return (n % 2) == 1
end

function mbrot(x,y,x0,y0)
    local rx, ry = x^2-y^2 + x0, 2*x*y + y0
    if rx^2 + ry^2 > 4 then
        return false
    else
        return rx, ry
    end
end

function iterate(x0,y0,maxiter)
    local x, y, x2, y2 = x0, y0, x0, y0
    for i = 1, maxiter do
        -- iterate twice as fast to check for loops
        x2, y2 = mbrot(x2,y2,x0,y0)
        if not x2 then return 2*i-1 end
        if x == x2 and y == y2 then return maxiter end
        x2, y2 = mbrot(x2,y2,x0,y0)
        if not x2 then return 2*i end
        if x == x2 and y == y2 then return maxiter end
        -- iterate
        x, y = mbrot(x,y,x0,y0)
        if not x then return i end
    end
    return maxiter
end

-- -------------------------------------------------------------------------

function iter(max)
    local logical, real = coordinates()
    local function drawer(maxiter)
        return function(x,y)
	    local x, y = logical(x,y)
            return modcolor(iterate(x,y,maxiter))
        end
    end
    for i = 1, max or 150 do
	local vi = 2*math.floor(i+1.3^(i-3))
	print(i,vi)
        display.udp.fungfx(drawer(vi))
    end
end

iter()

