local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

local deserialize = dofile(MP .. "/deserialize.lua")
local localize_nodeids = dofile(MP .. "/localize_nodeids.lua")

local function get_mapblock_pos(pos)
  return vector.floor( vector.divide(pos, 16))
end

local function get_mapblock_name(prefix, pos, suffix)
  return prefix .. "/" .. pos.x .. "/mapblock_" ..
    pos.y .. "_" .. pos.z .. "." .. suffix
end

local function read_compressed(filename)
  local file = io.open(filename, "rb")
  if file then
    local data = file:read("*all")
    return minetest.decompress(data, "deflate")
  end
end

local function read_mapblock_data(mapblock)
  local json = read_compressed(get_mapblock_name(MP .. "/map/", mapblock, "bin"))
  if not json then
    return
  end
  return minetest.parse_json(json)
end

return function(manifest)
  minetest.register_on_generated(function(minp, maxp)
    local min_mapblock = get_mapblock_pos(minp)
    local max_mapblock = get_mapblock_pos(maxp)

    for x = min_mapblock.x, max_mapblock.x do
      for y = min_mapblock.y, max_mapblock.y do
        for z = min_mapblock.z, max_mapblock.z do
          local mapblock = { x=x, y=y, z=z }

          -- get data if available
          local data = read_mapblock_data(mapblock)
          if data then
            -- localize node-ids
            localize_nodeids(manifest.node_mapping, data.node_ids)

            -- deserialize to map
            deserialize(data, mapblock)
          end
        end
      end
    end
  end)

end
