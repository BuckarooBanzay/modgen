local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

local deserialize = dofile(MP .. "/deserialize.lua")
local localize_nodeids = dofile(MP .. "/localize_nodeids.lua")

local function get_mapblock_pos(pos)
  return vector.floor( vector.divide(pos, 16))
end

local function get_mapblock_name(prefix, pos, suffix)
  if minetest.get_modpath("modgen") then
    -- use the "get_mapblock_name" function from the base mod or override
    -- allows to use other patterns for file names (hashes, etc)
    return modgen.get_mapblock_name(prefix, pos, suffix)
  end

	return prefix .. "mapblock-" ..
		pos.x .. "_" .. pos.y .. "_" .. pos.z .. "." .. suffix
end

local function read_compressed(filename)
  local file = io.open(filename, "rb")
  if file then
    local data = file:read("*all")
    return minetest.decompress(data, "deflate")
  end
end

local function read_mapblock_data(mapblock)
  local nodedata = read_compressed(get_mapblock_name(MP .. "/map/", mapblock, "bin"))

  if nodedata then
    -- get optional metadata
    local metadata = read_compressed(get_mapblock_name(MP .. "/map/", mapblock, "meta.bin"))

    local result = {
      node_ids = {},
      param1 = {},
      param2 = {},
      metadata = minetest.parse_json(metadata or "{}")
    }

    for i=1,4096 do
      -- 1, 3, 5 ... 8191
      local node_id_offset = (i * 2) - 1
      local node_id = (string.byte(nodedata, node_id_offset) * 256) +
        string.byte(nodedata, node_id_offset+1) - 32768

      local param1 = string.byte(nodedata, (4096 * 2) + i)
      local param2 = string.byte(nodedata, (4096 * 3) + i)

      table.insert(result.node_ids, node_id)
      table.insert(result.param1, param1)
      table.insert(result.param2, param2)
    end

    return result
  end
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
