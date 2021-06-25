
local autosave_meta_key = "modgen_autosave"

function modgen.set_autosave(playername, enabled)
    local player = minetest.get_player_by_name(playername)
    if player then
        -- persist in player meta
        local meta = player:get_meta()
        meta:set_int(autosave_meta_key, enabled and 1 or 0)
    end
end


local function place_dig_callback(pos, _, player)
    if not player then
        return
    end

    local meta = player:get_meta()
    if meta:get_int(autosave_meta_key) == 1 then
        -- TODO: defer export
        local playername = player:get_player_name()
        modgen.export(playername, pos, pos, true, true)
    end
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
            modgen.export("singleplayer", pos1, pos2, true, true)
            return old_fn(...)
        end
    end

    worldedit_intercept("set", function(pos1, pos2) return pos1, pos2 end)
    worldedit_intercept("set_param2", function(pos1, pos2) return pos1, pos2 end)
    worldedit_intercept("replace", function(pos1, pos2) return pos1, pos2 end)
    -- TODO: stack/copy
    -- TODO: defer export
end