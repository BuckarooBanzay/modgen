local MP = minetest.get_modpath("modgen")

-- mod namespace
modgen = {
  pos1 = {},
  pos2 = {},
  MOD_PATH = MP,
  PART_LENGTH = 16,
  export_path = minetest.get_worldpath() .. "/modgen_mod_export"
}

dofile(MP.."/functions.lua")
dofile(MP.."/markers.lua")
dofile(MP.."/register.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/iterator_next.lua")
dofile(MP.."/commands/export.lua")
dofile(MP.."/commands/pos.lua")
