modgen mod for minetest

![](https://github.com/BuckarooBanzay/modgen/workflows/luacheck/badge.svg)
[![License](https://img.shields.io/badge/License-MIT%20and%20CC%20BY--SA%203.0-green.svg)](license.txt)
[![Download](https://img.shields.io/badge/Download-ContentDB-blue.svg)](https://content.minetest.net/packages/BuckarooBanzay/modgen)

# Overview

Allows you to export a part of the map as a standalone mod which can be used as a mapgen

# Commands

* `/pos1`, `/pos2` Set opposite corners of the export map
* `/export [fast]` Exports the map as a standalone mod into `${worldfolder}/modgen_mod_export`
* `/autosave [on|off]` enables autosave feature (**warning**: may impact performance!)

# In-place saving

After an initial mod-export the resulting mod can be edited live and in-place
if the `modgen` mod is also present (optional).

To enable the saving directly into the exported mod you have to add it to the "trusted_mods" setting:

```
secure.trusted_mods = modgen
```

Afterwards if you mark a region and execute `/export` the mapblocks are written to the exported mod itself

# Export format

## manifest.json

Json file that serves as an index to look up content-id's and spawn-position:

```json
{
  "next_id": 82,
  "node_mapping": {
    "access_cards:palm_scanner_off": 25,
    "air": 0,
    "default:chest": 53,
    "digilines:wire_std_00100000": 72
  },
  "spawn_pos": {
    "x": 7,
    "y": 8,
    "z": 22
  }
}
```

## mapblocks

Mapblocks are saved in `${modfolder}/map/mapblock-x_y_z.bin`
**Hint**: x/y/z are the coordinates in mapblocks

The mapdata is saved and compressed with `deflate`

* 4096*2 Bytes: Node-ids for the mapblock in z/y/x order as integer MSB first
* 4096 Bytes: Param1 data
* 4096 Bytes: Param2 data

## metadata / nodetimers

Metadata and nodetimers are saved as compressed (`deflate` algorithm) json-file in `${modfolder}/map/mapblock-x_y_z.meta.bin`

```json
{
  "meta": {
    "(1,3,14)": {
      "fields": {
        "configured": "1",
        "key": "Level 1 Access"
      },
      "inventory": null
    },
    "(11,3,14)": {
      "fields": {
        "configured": "1",
        "key": "Biolab Access"
      },
      "inventory": null
    },
    "(13,7,10)": {
      "fields": {
        "gain": "2",
        "hear_distance": "32",
        "interval_max": "20",
        "interval_min": "20",
        "randomize_position": "0",
        "selected_sound_key": "soundblock_scifi_ambient_3",
        "state": "on"
      },
      "inventory": null
    },
    "(8,7,10)": {
      "fields": {
        "formspec": "size[8,9]list[current_name;main;0,0.3;8,4;]list[current_player;main;0,4.85;8,1;]list[current_player;main;0,6.08;8,3;8]listring[current_name;main]listring[current_player;main]image[0,4.85;1,1;gui_hb_bg.png]image[1,4.85;1,1;gui_hb_bg.png]image[2,4.85;1,1;gui_hb_bg.png]image[3,4.85;1,1;gui_hb_bg.png]image[4,4.85;1,1;gui_hb_bg.png]image[5,4.85;1,1;gui_hb_bg.png]image[6,4.85;1,1;gui_hb_bg.png]image[7,4.85;1,1;gui_hb_bg.png]",
        "infotext": "Box"
      },
      "inventory": {
        "main": [
          ""
        ]
      }
    },
    "(9,8,10)": {
      "fields": {
        "formspec": "size[8,9]list[current_name;main;0,0.3;8,4;]list[current_player;main;0,4.85;8,1;]list[current_player;main;0,6.08;8,3;8]listring[current_name;main]listring[current_player;main]image[0,4.85;1,1;gui_hb_bg.png]image[1,4.85;1,1;gui_hb_bg.png]image[2,4.85;1,1;gui_hb_bg.png]image[3,4.85;1,1;gui_hb_bg.png]image[4,4.85;1,1;gui_hb_bg.png]image[5,4.85;1,1;gui_hb_bg.png]image[6,4.85;1,1;gui_hb_bg.png]image[7,4.85;1,1;gui_hb_bg.png]",
        "infotext": "Box"
      },
      "inventory": {
        "main": [
          ""
        ]
      }
    }
  },
  "timers": {
    "(13,7,10)": {
      "elapsed": 5.200000286102295,
      "timeout": 20
    }
  }
}

```

# License

MIT
