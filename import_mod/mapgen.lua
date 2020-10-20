local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

local deserialize = dofile(MP .. "/deserialize.lua")
local read_manifest = dofile(MP .. "/read_manifest.lua")

local function get_mapblock_pos(pos)
  return {
    x = math.floor(pos.x / 16),
    y = math.floor(pos.y / 16),
    z = math.floor(pos.z / 16)
  }
end

local function get_mapblock_name(prefix, pos, suffix)
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
  local metadata = read_compressed(get_mapblock_name(MP .. "/map/", mapblock, "meta.bin"))

  if nodedata then
    local result = {
      -- TODO
    }

    -- TODO: metadata

    return result
  end
end

return function()

  local manifest = read_manifest()
  print(dump(manifest))

  minetest.register_on_generated(function(minp, maxp)
    local min_mapblock = get_mapblock_pos(minp)
    local max_mapblock = get_mapblock_pos(maxp)

    for x = min_mapblock.x, max_mapblock.x do
      for y = min_mapblock.y, max_mapblock.y do
        for z = min_mapblock.z, max_mapblock.z do
          if x >= 0 or y >= 0 or z >= 0 then
            local mapblock = { x=x, y=y, z=z }
            print("[modgen mapgen]", dump(mapblock))

            local data = read_mapblock_data(mapblock)
            if data then
              -- deserialize
              deserialize(data, mapblock)
            end

          end
        end
      end
    end
  end)

end
