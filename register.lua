
-- used as callback from already exported mods
function modgen.register_import_mod(manifest, modpath)

  if modgen.enable_inplace_save then
    -- set export target to import-mod directly if the files are accessible
    modgen.export_path = modpath

    -- set this as active manifest
    modgen.import_manifest = manifest

    -- use next id value
    modgen.next_id = manifest.next_id

    -- use existing node_mapping
    modgen.node_mapping = manifest.node_mapping
  end


end
