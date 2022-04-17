ARG ENGINE_VERSION=5.5.0
FROM registry.gitlab.com/minetest/minetest/server:${ENGINE_VERSION}

COPY ./entrypoint.sh /entrypoint.sh
COPY ./stages/ /stages/

ENTRYPOINT /entrypoint.sh