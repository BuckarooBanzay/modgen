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
mapgen(manifest)

if config.enable_spawnpoint then
  -- initialize player spawn point
  spawn(manifest);
end

if minetest.get_modpath("modgen") then
  -- modgen available

  -- set current map export limits to modgen.pos1/pos2
  -- this allows re-exporting a map 1:1 with just the /export command
  minetest.after(0, function()
    local origin = { x=0, y=0, z=0 }
    modgen.set_pos(1, "singleplayer", origin)
    modgen.set_pos(2, "singleplayer", vector.multiply(manifest.size_mapblocks, 16))
  end)
end
