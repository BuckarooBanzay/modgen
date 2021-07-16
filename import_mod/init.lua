--- Modgen import mod
-- writes the mapblocks back to the world
-- dependency- and global-free

-- mod name and path
local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

-- storage
local storage = minetest.get_mod_storage()

-- local functions/helpers
local mapgen = dofile(MP .. "/mapgen.lua")
local read_manifest = dofile(MP .. "/read_manifest.lua")
local nodename_check = dofile(MP .. "/nodename_check.lua")

local manifest = read_manifest()
local world_uid = storage:get_string("uid")
if world_uid ~= "" and world_uid ~= manifest.uid then
  -- abort if the uids don't match, something fishy might be going on
  error("modgen uids don't match, aborting for your safety!")
end

-- write modgen uid to world-storage
storage:set_string("uid", manifest.uid)

-- check if the nodes are available in the current world
minetest.register_on_mods_loaded(function()
  nodename_check(manifest)
end)

-- initialize mapgen
mapgen(manifest)

if minetest.get_modpath("modgen") then
  -- modgen available, make it aware of the loaded import_mod
  modgen.register_import_mod(manifest, MP)
end
