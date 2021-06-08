local MP = minetest.get_modpath("modgen")

-- mod namespace
modgen = {
  pos1 = {},
  pos2 = {},
  MOD_PATH = MP,
  PART_LENGTH = 16,

  -- nodename to id mapping
  node_mapping = {},

  -- next mapping id
  next_id = 0,

  -- export path for the generated mod
  export_path = minetest.get_worldpath() .. "/modgen_mod_export",

  -- manifest of already existing import-mod if available
  import_manifest = nil,

  -- enables saving mapblocks in-place
  enable_inplace_save = false
}

-- secure/insecure environment
local global_env = _G

local ie = minetest.request_insecure_environment()
if ie then
  print("[modgen] using insecure environment")
  -- register insecure environment
  global_env = ie

  -- enable in-place saving
  modgen.enable_inplace_save = true
end

-- pass on global env (secure/insecure)
loadfile(MP.."/functions.lua")(global_env)

dofile(MP.."/markers.lua")
dofile(MP.."/register.lua")
dofile(MP.."/serialize.lua")
dofile(MP.."/iterator_next.lua")
dofile(MP.."/export.lua")
dofile(MP.."/commands/export.lua")
dofile(MP.."/commands/autosave.lua")
dofile(MP.."/commands/pos.lua")

