modgen mod for minetest

![](https://github.com/BuckarooBanzay/modgen/workflows/luacheck/badge.svg)
![](https://github.com/BuckarooBanzay/modgen/workflows/test/badge.svg)
[![License](https://img.shields.io/badge/License-MIT%20and%20CC%20BY--SA%203.0-green.svg)](license.txt)
[![Download](https://img.shields.io/badge/Download-ContentDB-blue.svg)](https://content.minetest.net/packages/BuckarooBanzay/modgen)

# Overview

Allows you to export a part of the map as a standalone mod which can be used as a mapgen

Api docs: https://buckaroobanzay.github.io/modgen/

Demo: https://github.com/BuckarooBanzay/mesecons_lab

![Screenshot](./screenshot.png)

# Commands

* `/pos1`, `/pos2` Set opposite corners of the export map
* `/export [fast]` Exports the map as a standalone mod into `${worldfolder}/modgen_mod_export`
* `/modgen_stats` Returns some stats about the exported chunks and size
* `/autosave [on|off]` enables autosave feature (**warning**: may not work on some worldedit commands)

# In-place saving

After an initial mod-export the resulting mod can be edited live and in-place
if the `modgen` mod is also present (optional).

To enable the saving directly into the exported mod you have to add it to the "trusted_mods" setting:

```
secure.trusted_mods = modgen
```

Afterwards if you mark a region and execute `/export` the chunks are written to the exported mod itself

# Export format

## manifest.json

Json file that serves as an index to look up content-id's:

```json
{
  "next_id": 82,
  "node_mapping": {
    "access_cards:palm_scanner_off": 25,
    "air": 0,
    "default:chest": 53,
    "digilines:wire_std_00100000": 72
  }
}
```

## chunks

Mapblocks are exported in chunks with the following path-structure: `${export-mod}/map/chunk_${x}_${y}_${z}.bin`

## versions

Major versions with breaking changes:

* Version `1`: Initial release
* Version `2`: Reordered export axes from `z-x-y` to `z-x-y` (30% size decrease)
* Version `3`: Export whole chunks (50% size decrease)

# Testing

Requirements:
* Docker
* docker-compose

Usage:
```bash
docker-compose -f docker-compose.test.yml up --build sut
```

# License

MIT
