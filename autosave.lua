

-- list of mapblocks marked for export
local mapblocks = {}

-- autosave worker function
local function worker()
    local count = 0
    for hash in pairs(mapblocks) do
        count = count + 1
        local mapblock_pos = minetest.get_position_from_hash(hash)
        local pos = modgen.get_mapblock_bounds_from_mapblock(mapblock_pos)
        modgen.export("singleplayer", pos, pos, true, false)
    end

    if count > 0 then
        minetest.chat_send_all("Dispatched " .. count .. " mapblocks to export")
    end
    mapblocks = {}
    minetest.after(2, worker)
end

minetest.after(1, worker)

local function deferred_export(pos1, pos2)
    if not modgen.autosave then
        return
    end

    pos1, pos2 = modgen.sort_pos(pos1, pos2)

    local mapblock_pos1 = modgen.get_mapblock(pos1)
    local mapblock_pos2 = modgen.get_mapblock(pos2)
    for x=mapblock_pos1.x,mapblock_pos2.x do
        for y=mapblock_pos1.y,mapblock_pos2.y do
            for z=mapblock_pos1.z,mapblock_pos2.z do
                local mapblock_pos = {x=x, y=y, z=z}
                local hash = minetest.hash_node_position(mapblock_pos)
                mapblocks[hash] = true
            end
        end
    end
end

local function place_dig_callback(pos)
    deferred_export(pos, pos)
end

-- autosave on place/dignode
minetest.register_on_placenode(place_dig_callback)
minetest.register_on_dignode(place_dig_callback)

-- autosave on we commands
if minetest.get_modpath("worldedit") then

    -- generic worldedit command interceptor function
    local function worldedit_intercept(function_name, affected_positions_callback)
        local old_fn = worldedit[function_name]

        worldedit[function_name] = function(...)
            local pos1, pos2 = affected_positions_callback(...)
            deferred_export(pos1, pos2)
            return old_fn(...)
        end
    end

    -- covers //set //move
    worldedit_intercept("set", function(pos1, pos2) return pos1, pos2 end)
    -- covers //param2
    worldedit_intercept("set_param2", function(pos1, pos2) return pos1, pos2 end)
    -- covers //replace
    worldedit_intercept("replace", function(pos1, pos2) return pos1, pos2 end)
    -- covers //copy //stack
    worldedit_intercept("copy2", function(pos1, pos2, off)
        return vector.add(pos1, off), vector.add(pos2, off)
    end)
end

minetest.register_on_mods_loaded(function()
    for nodename, def in pairs(minetest.registered_nodes) do
        if type(def.on_receive_fields) == "function" then
            -- intercept formspec events
            local old_on_receive_fields = def.on_receive_fields
            minetest.override_item(nodename, {
                on_receive_fields = function(pos, formname, fields, sender)
                    deferred_export(pos, pos)
                    return old_on_receive_fields(pos, formname, fields, sender)
                end
            })
        end

        if type(def.on_metadata_inventory_move) == "function" then
            -- intercept inv move event
            local old_inv_move = def.on_metadata_inventory_move
            minetest.override_item(nodename, {
                on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
                    deferred_export(pos, pos)
                    return old_inv_move(pos, from_list, from_index, to_list, to_index, count, player)
                end
            })
        end

        if type(def.on_metadata_inventory_put) == "function" then
            -- intercept inv put event
            local old_inv_put = def.on_metadata_inventory_put
            minetest.override_item(nodename, {
                on_metadata_inventory_put = function(pos, listname, index, stack, player)
                    deferred_export(pos, pos)
                    return old_inv_put(pos, listname, index, stack, player)
                end
            })
        end

        if type(def.on_metadata_inventory_take) == "function" then
            -- intercept inv take event
            local old_inv_take = def.on_metadata_inventory_take
            minetest.override_item(nodename, {
                on_metadata_inventory_take = function(pos, listname, index, stack, player)
                    deferred_export(pos, pos)
                    return old_inv_take(pos, listname, index, stack, player)
                end
            })
        end

    end
end)