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
  local chunk_data = read_compressed(filename)
  if not chunk_data then
    return
  end
  local mapblock_count = string.byte(chunk_data, 1)

  local manifest_offset = 1 + 1 + (4096 * 4 * mapblock_count)
  local chunk_manifest = minetest.parse_json(string.sub(chunk_data, manifest_offset))

  for mbi=1, mapblock_count do
    local mapblock_manifest = chunk_manifest.mapblocks[mbi]
    local mapblock = {
      node_ids = {},
      param1 = {},
      param2 = {},
      metadata = mapblock_manifest.metadata
    }

    for i=1,4096 do
      local node_id_offset = 1 + ((mbi-1) * 4096 * 2) + (i * 2) - 2
      local node_id = decode_uint16(chunk_data, node_id_offset)
      local param1 = string.byte(chunk_data, 1 + (4096 * 2 * mapblock_count) + ((mbi-1) * 4096) + i)
      local param2 = string.byte(chunk_data, 1 + (4096 * 3 * mapblock_count) + ((mbi-1) * 4096) + i)

      table.insert(mapblock.node_ids, node_id)
      table.insert(mapblock.param1, param1)
      table.insert(mapblock.param2, param2)
    end

    localize_nodeids(manifest.node_mapping, mapblock.node_ids)
    deserialize(mapblock, mapblock_manifest.pos)
end
end

return function(manifest)
  minetest.register_on_generated(function(minp)
    load_chunk(get_chunkpos(minp), manifest)
  end)
end
