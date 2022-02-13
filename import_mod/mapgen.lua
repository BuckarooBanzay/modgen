local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

local deserialize = dofile(MP .. "/deserialize.lua")
local localize_nodeids = dofile(MP .. "/localize_nodeids.lua")

local function decode_uint16(str, ofs)
  ofs = ofs or 0
  local a, b = string.byte(str, ofs + 1, ofs + 2)
  return a + b * 0x100
end

local function get_mapblock_pos(pos)
  return vector.floor( vector.divide(pos, 16))
end

local function get_chunkpos(pos)
	local mapblock_pos = get_mapblock_pos(pos)
	local aligned_mapblock_pos = vector.add(mapblock_pos, 2)
	return vector.floor( vector.divide(aligned_mapblock_pos, 5) )
end

local function get_chunk_name(prefix, chunk_pos)
  return prefix .. "/chunk_" .. chunk_pos.x .. "_" .. chunk_pos.y .. "_" .. chunk_pos.z .. ".bin"
end

local function read_compressed(filename)
  local file = io.open(filename, "rb")
  if file then
    local data = file:read("*all")
    return minetest.decompress(data, "deflate"), #data
  end
end

local function load_chunk(chunk_pos, manifest)
  local filename = get_chunk_name(MP .. "/map/", chunk_pos)
  local chunk_data, compressed_size = read_compressed(filename)
  if not chunk_data then
    return
  end
  print("loaded chunk: " .. minetest.pos_to_string(chunk_pos) .. " with " .. compressed_size .. "/" .. #chunk_data .. " bytes")
  local mapblock_count = string.byte(chunk_data, 1)
  print("mapblock-count: " .. mapblock_count)

  local manifest_offset = 1 + 1 + (4096 * 4 * mapblock_count)
  local chunk_manifest = minetest.parse_json(string.sub(chunk_data, manifest_offset))

  for mbi=1, mapblock_count do
    local mapblock = {
      node_ids = {},
      param1 = {},
      param2 = {}
    }

    for i=1,4096 do
      local node_id_offset = 1 + (mbi * 4096) + (i * 2)
      local node_id = decode_uint16(chunk_data, node_id_offset)
      local param1 = string.byte(chunk_data, 1 + (mbi * 4096 * 2 * mapblock_count) + i)
      local param2 = string.byte(chunk_data, 1 + (mbi * 4096 * 3 * mapblock_count) + i)

      table.insert(mapblock.node_ids, node_id)
      table.insert(mapblock.param1, param1)
      table.insert(mapblock.param2, param2)
    end

    localize_nodeids(manifest.node_mapping, mapblock.node_ids)
    deserialize(mapblock, chunk_manifest.mapblocks[mbi].pos)
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
  minetest.register_on_generated(function(minp)
    local chunk_pos = get_chunkpos(minp)
    load_chunk(chunk_pos, manifest)
    --[[

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
    --]]
  end)

end
