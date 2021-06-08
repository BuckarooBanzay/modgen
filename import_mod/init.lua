-- mod name and path
local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

-- local functions/helpers
local mapgen = dofile(MP .. "/mapgen.lua")
local read_manifest = dofile(MP .. "/read_manifest.lua")

local manifest = read_manifest()

-- initialize mapgen
mapgen(manifest)

if minetest.get_modpath("modgen") then
  -- modgen available, make it aware of the loaded import_mod
  modgen.register_import_mod(manifest, MP)
end
