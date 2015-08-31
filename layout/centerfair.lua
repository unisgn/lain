
--[[
                                                 
     Licensed under GNU General Public License v2
      * (c) 2014,      projektile                
      * (c) 2013,      Luke Bonham               
      * (c) 2010,      Nicolas Estibals          
      * (c) 2010-2012, Peter Hofmann             
                                                 
--]]

local tag       = require("awful.tag")
local beautiful = require("beautiful")
local math      = { ceil  = math.ceil,
                    floor = math.floor,
                    max   = math.max }
local tonumber  = tonumber

local centerfair  = { name = "centerfair" }

function centerfair.arrange(p)
    -- Layout with fixed number of vertical columns (read from nmaster).
    -- Cols are centerded until there is nmaster columns, then windows
    -- are stacked in the slave columns, with at most ncol clients per
    -- column if possible.

    -- with nmaster=3 and ncol=1 you'll have
    --        (1)                (2)                (3)
    --   +---+---+---+      +-+---+---+-+      +---+---+---+
    --   |   |   |   |      | |   |   | |      |   |   |   |
    --   |   | 1 |   |  ->  | | 1 | 2 | | ->   | 1 | 2 | 3 |  ->
    --   |   |   |   |      | |   |   | |      |   |   |   |
    --   +---+---+---+      +-+---+---+-+      +---+---+---+

    --        (4)                (5)
    --   +---+---+---+      +---+---+---+
    --   |   |   | 3 |      |   | 2 | 4 |
    --   + 1 + 2 +---+  ->  + 1 +---+---+
    --   |   |   | 4 |      |   | 3 | 5 |
    --   +---+---+---+      +---+---+---+

    -- A useless gap (like the dwm patch) can be defined with
    -- beautiful.useless_gap_width .
    local useless_gap = tonumber(beautiful.useless_gap_width) or 0
    if useless_gap < 0 then useless_gap = 0 end

    -- A global border can be defined with
    -- beautiful.global_border_width
    local global_border = tonumber(beautiful.global_border_width) or 0
    if global_border < 0 then global_border = 0 end

    -- Themes border width requires an offset
    local bw = tonumber(beautiful.border_width) or 0

    -- Screen.
    local wa = p.workarea
    local cls = p.clients

    -- Borders are factored in.
    wa.height = wa.height - (global_border * 2)
    wa.width = wa.width - (global_border * 2)

    -- How many vertical columns? Read from nmaster on the tag.
    local t = tag.selected(p.screen)
    local num_x = centerfair.nmaster or tag.getnmaster(t)
    local ncol = centerfair.ncol or tag.getncol(t)
    if num_x <= 2 then num_x = 2 end

    local width = math.floor((wa.width - (num_x + 1)*useless_gap - num_x*2*bw) / num_x)

    local offset_y = wa.y + useless_gap
    if #cls < num_x
    then
        -- Less clients than the number of columns, let's center it!
        local offset_x = wa.x + (wa.width - #cls*width - #cls*2*bw - (#cls - 1)*useless_gap) / 2
        local g = {}
        g.width = width
        g.height = wa.height - 2*useless_gap - 2*bw
        g.y = offset_y + global_border
        for i = 1, #cls do
            g.x = offset_x + (i - 1) * (width + useless_gap + 2*bw) + global_border
            cls[i]:geometry(g)
        end
    else
        -- More clients than the number of columns, let's arrange it!
        local offset_x = wa.x
        if useless_gap > 0 then
           offset_x = offset_x
        end

        -- Master client deserves a special treatement
        local g = {}
        g.width = wa.width - ((num_x - 1)*width + (num_x + 1)*useless_gap + num_x*2*bw)
        g.height = wa.height - 2*useless_gap - 2*bw
        g.x = offset_x + useless_gap + global_border
        g.y = offset_y + global_border

        cls[1]:geometry(g)

        -- Treat the other clients

        -- Compute distribution of clients among columns
        local num_y ={}
        do
            local remaining_clients = #cls-1
            local ncol_min = math.ceil(remaining_clients/(num_x-1))
            if ncol >= ncol_min
            then
                for i = (num_x-1), 1, -1 do
                    if (remaining_clients-i+1) < ncol
                    then
                        num_y[i] = remaining_clients-i + 1
                    else
                        num_y[i] = ncol
                    end
                    remaining_clients = remaining_clients - num_y[i]
                end
            else
                local rem = remaining_clients % (num_x-1)
                if rem ==0
                then
                    for i = 1, num_x-1 do
                        num_y[i] = ncol_min
                    end
                else
                    for i = 1, num_x-1 do
                        num_y[i] = ncol_min - 1
                    end
                    for i = 0, rem-1 do
                        num_y[num_x-1-i] = num_y[num_x-1-i] + 1
                    end
                end
            end
        end

        -- Compute geometry of the other clients
        local nclient = 2 -- we start with the 2nd client
        g.x = g.x + g.width + 2*bw + useless_gap
        g.width = width

        for i = 1, (num_x-1) do
            g.height = math.floor((wa.height - (num_y[i] + 1)*useless_gap - num_y[i]*2*bw) / num_y[i])
            g.y = offset_y + global_border
            for j = 0, (num_y[i]-2) do
                cls[nclient]:geometry(g)
                nclient = nclient + 1
                g.y = g.y + g.height + 2*bw + useless_gap
            end
            g.height = wa.height - (num_y[i] + 1)*useless_gap - (num_y[i]-1)*g.height - num_y[i]*2*bw
            cls[nclient]:geometry(g)
            nclient = nclient + 1
            g.x = g.x + g.width + 2*bw + useless_gap
        end
    end
end

return centerfair
