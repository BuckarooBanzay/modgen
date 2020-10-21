-- mod name and path
local modname = minetest.get_current_modname()
local MP = minetest.get_modpath(modname)

-- local functions/helpers
local mapgen = dofile(MP .. "/mapgen.lua")
local spawn = dofile(MP .. "/spawn.lua")
local config = dofile(MP .. "/config.lua")
local read_manifest = dofile(MP .. "/read_manifest.lua")

local manifest = read_manifest()

-- initialize mapgen
mapgen()

if config.enable_spawnpoint then
  -- initialize player spawn point
  spawn(manifest);
end
