
-- used as callback from already exported mods
function modgen.register_import_mod(manifest, modpath)

  if manifest.version ~= modgen.version then
    -- hard-fail if the versions don't match
    error("modgen and modgen_export versions don't match, try up- or downgrading the modgen mod")
  end

  -- initialize stats
  manifest.size = manifest.size or 0
  manifest.mapblock_count = manifest.mapblock_count or 0
  manifest.metadata_count = manifest.metadata_count or 0

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
