local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

local deserialize = dofile(MP .. "/deserialize.lua")

local function get_mapblock_pos(pos)
  return {
    x = math.floor(pos.x / 16),
    y = math.floor(pos.y / 16),
    z = math.floor(pos.z / 16)
  }
end

return function()

  minetest.register_on_generated(function(minp, maxp)
    local min_mapblock = get_mapblock_pos(minp)
    local max_mapblock = get_mapblock_pos(maxp)

    for x = min_mapblock.x, max_mapblock.x do
      for y = min_mapblock.y, max_mapblock.y do
        for z = min_mapblock.z, max_mapblock.z do
          if x >= 0 or y >= 0 or z >= 0 then
            local mapblock = { x=x, y=y, z=z }
            print("[modgen mapgen]", dump(mapblock))
          end
        end
      end
    end
  end)

end
