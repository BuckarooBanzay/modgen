#!/bin/sh

set -e

echo "Preparing stage1: smoketests"
cp -R /stages/stage1 /root/.minetest/worlds/world/worldmods/stage1

cat << EOF > /minetest.conf
default_game = minetest_game
mg_name = v7
enable_integration_test = true
EOF

echo "Executing stage1"
minetestserver --config /minetest.conf

echo "Cleanup"
rm -rf /root/.minetest/worlds/world/worldmods/stage1

echo "Preparing stage2: mapgen and export"
cp -R /stages/stage2 /root/.minetest/worlds/world/worldmods/stage2

cat << EOF > /minetest.conf
default_game = minetest_game
mg_name = v7
enable_integration_test = true
EOF

echo "Executing stage2"
minetestserver --config /minetest.conf

test -d /root/.minetest/worlds/world/modgen_mod_export