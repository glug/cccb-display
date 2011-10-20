#!/usr/bin/lua
-- vim: set tw=76 ts=4 et :
-- -------------------------------------------------------------------------

require "display"


-- coordinate transforms

-- use point (x y 1)
-- matrix(a,b,c,d,e,f) = (a b 0 ; c d 0 ; e f 1)
-- transform is [x' y' 1] = point x matrix
-- <=>  x' = ax + cy + e
--      y' = bx + dy + f
-- matrix1(matrix2(point)) = (matrix2 x matrix1)(point)
-- translate(tx,ty) = matrix (1,0,0,1,tx,ty)
-- scale(sx,sy) = matrix (sx,0,0,sy,0,0)
-- rotate(r) = matrix (cos r, sin r, -sin r, cos r, 0, 0)
-- skew(rx,ry) = matrix (1,tan rx, tan ry, 1, 0, 0)
-- best combinated in sequence translate, rotate, scale|skew
function matrix_transform(xx,xy,yx,yy,tx,ty)
    return function(x,y)
        return x*xx + y*xy + tx, x*yx + y*yy + ty
    end
end

function screen_matrix()
    local rx = display.config.height
    local ry = display.config.vheight
    local xr2, yr2 = rx/2, ry/2
    local aspect = rx/ry
    return
end

function coordinates(lx,ly,w,h)
    local aspect = 1.8
    local w = w or aspect
    local h = h or 1
    local lx = lx or 0
    local ly = ly or 0
    local rx = display.config.width
    local ry = display.config.vheight

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

-- -------------------------------------------------------------------------

-- sphere functions

function sphere(x0,y0,r)
    x0, y0,r = x0 or 0, y0 or 0, r or 0.3
    return function(x,y)
        return (x-x0)^2 + (y-y0)^2 < r
    end
end

function polspherept(x0,y0,r,phi)
    return x0+r*math.sin(phi), y0+r*math.cos(phi)
end

--[[
function sphere(x0,y0,r,cmap,cunmap)
    x0, y0, r = x0 or 0, y0 or 0, r or 0.3
    return function(x,y)
        x, y = cmap(x,y)
        return ( (x-x0)^2 + (y-y0)^yp < r)
    end

--]]

-- -------------------------------------------------------------------------


-- RNGs

local twopi = 2*math.pi

randomAngle = function() return math.random()*2*math.pi end

moveDirection = function(phi,phi2)
    if phi < phi2 then
        local l1 = phi2-phi
        local l2 = phi + (twopi-phi2)
        if l1 <= l2 then
            return 1, l1
        else
            return -1, l2
        end
    else
        local sgm, dist = moveDirection(phi2,phi)
        return -sgm, dist
    end
end

-- -------------------------------------------------------------------------

-- tower creation & drawing

radi =  {
        0.38196601125011,
        0.23606797749979,
        0.14589803375032,
        0.090169943749474,
        0.055728090000841,
        0.034441853748633,
--        0.021286236252208,
--        0.013155617496425,
--        0.0081306187557833,
--        0.0050249987406415,
--        0.0031056200151419,
--        0.0019193787254996,
--        0.0011862412896422,
--        0.0007331374358574,
--        0.00045310385378482,
        }

mkTower = function()
    local t = {}
    for _,r in pairs(radi) do
        t[#t+1] = {r,randomAngle()}
    end
    return t
end

function mkTowerDrawer(t)
    local dfuns = {}
    local x0, y0 = 0, 0
    for _,circ in pairs(t) do
        local r, phi = circ[1], circ[2]
        table.insert(dfuns,sphere(x0,y0,r))
        x0, y0 = x0 + r*math.sin(phi), y0 + r*math.cos(phi)
    end

    local checkFun = function(x,y)
        local cl = false
        for k, f in ipairs(dfuns) do
            if f(x,y) then cl = (math.fmod(k,2) ~= 0) end
        end
        return cl
    end

    return checkFun
end

-- -------------------------------------------------------------------------

-- 8 frames per change, min. 0.1 or full delta

function test()
    local tree = mkTower()

    local logical, real = coordinates()

    while true do

        -- go to next position
        
        local target = mkTower()

        for i=1,math.random(10,50) do

            -- draw

            local drawer = (function()
                local drw = mkTowerDrawer(tree)
                return function(x,y) return drw(logical(x,y)) end
            end)()

            display.udp.fungfx(drawer)

            -- move

            for k,t in pairs(tree) do
                if math.abs(t[2]-target[k][2]) < 0.05 then
                    t[2] = target[k][2]
                else
                    local sgn,dist = moveDirection(t[2], target[k][2])
                    t[2] = t[2] + sgn*math.max(dist/10,0.025)
                end
            end
        end
    end
end

test()



--[[


xor = function(a,b)
    return (a or b) and not (a and b)
end

iter = function(n)
    local i = 0
    while i < n do
        local x0, y0, r = math.random()*aspect*2-aspect, math.random()*2-1, 1/math.random(2,50)
        --xp, yp = 2.7, 0.7 --1/math.random(1,50)*10, 1/math.random(1,50)*10
        local a = 0
        local f = sphere(x0,y0,r)
        for y = 1, ly do
            for x = 1,lx do
                local b = f(x,y)
                if b then
                    st[idx(x,y)] = xor(st[idx(x,y)], b)
                    a = a + 1
                end
            end
        end
        if a > 10 then
            i = i + 1
            print(string.format("%6.3f  %6.3f  %6.4f  %7.3f %7.3f  %7d", x0,y0,r,xp,yp,a))
            drawscreen(st)
        end
    end
end
--]]

--[[
st = {}
iter(100)

--]]

