--- chunk functions
--
-- Chunk on-disk format:
--
-- * uint8: # of stored mapblocks
-- * uint8[4096 * #mapblocks]: node-ids
-- * uint8[4096 * #mapblocks]: param1
-- * uint8[4096 * #mapblocks]: param2
-- * uint8[...]: chunk manifest in json format

-- copy environment to local scope
local env = ...

function modgen.export_chunk(chunk_pos, filename)
    local min_mapblock, max_mapblock = modgen.get_mapblock_bounds_from_chunk(chunk_pos)
    local mapblocks = {}
    for z=min_mapblock.z,max_mapblock.z do
        for x=min_mapblock.x,max_mapblock.x do
            for y=min_mapblock.y,max_mapblock.y do
                local mapblock_pos = {x=x, y=y, z=z}
                local mapblock = modgen.serialize_mapblock(mapblock_pos)
                if not mapblock.only_air then
                    table.insert(mapblocks, mapblock)
                end
            end
        end
    end

    local data = modgen.create_chunk_data(mapblocks)
    if not data then
        -- no data
        return 0
    end

    modgen.write_chunk_data(data, filename)
    return #data
end

function modgen.write_chunk_data(data, filename)
    print("write_chunk_data " .. filename .. " " .. #data .. " bytes")
    local file = env.io.open(filename,"wb")
    if not file then
        error("could not open file: " .. filename)
    end
	file:write(data)
	if file and file:close() then
		return
	else
		error("write to '" .. filename .. "' failed!")
	end
end

function modgen.create_chunk_data(mapblocks)
    if #mapblocks == 0 then
        return
    end

    local data = {}
    table.insert(data, string.char(#mapblocks))

    -- node_ids
    for _, mapblock in ipairs(mapblocks) do
        local node_ids = mapblock.node_ids
        for i=1,#node_ids do
            table.insert(data, modgen.encode_uint16(node_ids[i]))
        end
    end

    -- param1
    for _, mapblock in ipairs(mapblocks) do
        local param1 = mapblock.param1
        for i=1,#param1 do
            table.insert(data, string.char(param1[i]))
        end
    end

    -- param2
    for _, mapblock in ipairs(mapblocks) do
        local param2 = mapblock.param2
        for i=1,#param2 do
            table.insert(data, string.char(param2[i]))
        end
    end

    local chunk_manifest = {
        -- mapblock metadata and absolute positions
        mapblocks = {}
    }

    for _, mapblock in ipairs(mapblocks) do
        local mapblock_manifest = {
            pos = mapblock.pos,
        }

        if mapblock.has_metadata then
            -- add metadata
            mapblock_manifest.metadata = mapblock.metadata
        end

        table.insert(chunk_manifest.mapblocks, mapblock_manifest)
    end

    local json = minetest.write_json(chunk_manifest)
    table.insert(data, json)

    return minetest.compress(table.concat(data), "deflate")
end
