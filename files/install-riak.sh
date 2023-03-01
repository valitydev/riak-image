#!/bin/bash
set -e eu

# Build riak
mkdir -p /opt/riak && cd /opt/riak
curl -L https://github.com/basho/riak/archive/refs/tags/riak-${RIAK_VERSION}.tar.gz -o /opt/riak.tar.gz
tar zxf /opt/riak.tar.gz --strip-components 1
patch -p0 < /riak.schema.patch
patch < /rebar.config.patch
patch < /rebar.lock.patch
make all
./rebar3 as deb release --overlay_vars /vars.config
