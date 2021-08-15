-- copy environment to local scope
local env = ...


function modgen.export_chunk(chunk_pos)
    local min_mapblock, max_mapblock = modgen.get_mapblock_bounds_from_chunk(chunk_pos)
    local mapblocks = {}
    for z=min_mapblock.z,max_mapblock.z do
        for x=min_mapblock.x,max_mapblock.x do
            for y=min_mapblock.y,max_mapblock.y do
                local mapblock_pos = {x=x, y=y, z=z}
                local pos = modgen.get_mapblock_bounds_from_mapblock(mapblock_pos)
                print("Serializing mapblock: " .. minetest.pos_to_string(mapblock_pos))
                local mapblock = modgen.serialize_part(pos)
                if not mapblock.only_air then
                    table.insert(mapblocks, mapblock)
                end
            end
        end
    end

    print("Creating chunk data")
    local data = modgen.create_chunk_data(mapblocks)
    print("Created chunk data with " .. #data .. " bytes")
    local filename = modgen.export_path .. "/map/chunk_" ..
        chunk_pos.x .. "_" .. chunk_pos.y .. "_" .. chunk_pos.z .. ".bin"
    print("Writing chunk data")
    modgen.write_chunk_data(data, filename)
end

function modgen.write_chunk_data(data, filename)
    local file = env.io.open(filename,"wb")
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
    print("node_ids")
    for _, mapblock in ipairs(mapblocks) do
        local node_ids = mapblock.node_ids
        for i=1,#node_ids do
            table.insert(data, modgen.int_to_bytes(node_ids[i]))
        end
    end

    -- param1
    print("param1")
    for _, mapblock in ipairs(mapblocks) do
        local param1 = mapblock.param1
        for i=1,#param1 do
            table.insert(data, string.char(param1[i]))
        end
    end

    -- param2
    print("param2")
    for _, mapblock in ipairs(mapblocks) do
        local param2 = mapblock.param2
        for i=1,#param2 do
            table.insert(data, string.char(param2[i]))
        end
    end

    local chunk_manifest = {}
    -- TODO

    print("chunk manifest")
    local json = minetest.write_json(chunk_manifest)
    table.insert(data, json)

    print("compress")
    return minetest.compress(table.concat(data), "deflate")
end


minetest.register_chatcommand("test_chunk", {
    func = function()
        modgen.export_chunk({x=0,y=0,z=0})
    end
})
