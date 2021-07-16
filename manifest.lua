---------
-- manifest read/write functions

-- copy environment to local scope
local env = ...

-- add missing fields to existing manifests
local function migrate(manifest)
	manifest.uid = manifest.uid or modgen.create_uuid()
end

--- Writes the manifest to a file in json format
-- @param filename the filename to write to
function modgen.write_manifest(filename)
	-- migrate before exporting
	migrate(modgen.manifest)
	-- set mtime
	modgen.manifest.mtime = os.time()

	local file = env.io.open(filename,"w")
	local json = minetest.write_json(modgen.manifest, true)

	file:write(json)
	file:close()
end

--- Reads a minfest from a json file
-- @param filename the filename of the manifest
function modgen.read_manifest(filename)
	local infile = io.open(filename, "r")
	if not infile then
		-- no manifest file found
		return
	end

	local instr = infile:read("*a")
	infile:close()

	if instr then
		-- use existing manifest
		modgen.manifest = minetest.parse_json(instr)
		-- migrate on import
		migrate(modgen.manifest)
	end
end
