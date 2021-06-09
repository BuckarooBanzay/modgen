-- mod name and path
local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

-- local functions/helpers
local mapgen = dofile(MP .. "/mapgen.lua")
local read_manifest = dofile(MP .. "/read_manifest.lua")
local nodename_check = dofile(MP .. "/nodename_check.lua")

local manifest = read_manifest()

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
