local import_mod = ...

local function get_mod_chunk_mtime(chunk_pos)
    local _,_,mtime = import_mod.read_chunk_header(chunk_pos)
    return mtime
end

local function get_world_chunk_mtime(chunk_pos)
    local mtime = import_mod.storage:get_int(minetest.pos_to_string(chunk_pos))
    if mtime == 0 then
        return nil
    else
        return mtime
    end
end

local cache = {}
local function check_player_pos(player)
    local ppos = player:get_pos()
    local chunk_pos = import_mod.get_chunkpos(ppos)

    -- cache access
    local cache_key =minetest.pos_to_string(chunk_pos)
    if cache[cache_key] then
        return
    end
    cache[cache_key] = true

    -- retrieve timestamps
    local mod_mtime = get_mod_chunk_mtime(chunk_pos)
    local world_mtime = get_world_chunk_mtime(chunk_pos)

    if not mod_mtime then
        -- the chunk isn't available in the mod
        return
    end
    if not world_mtime then
        -- the chunk mtime has not been registered in-world
        return
    end

    -- TODO: compare timestamps and delete_area if a newer chunk is available
end

local function check_players()
    for _, player in ipairs(minetest.get_connected_players()) do
        check_player_pos(player)
    end
    minetest.after(1, check_players)
end

minetest.after(1, check_players)