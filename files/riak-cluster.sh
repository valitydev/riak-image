#!/bin/bash
#
# Cluster start script to bootstrap a Riak cluster.
#
sleep 10
set -x

if [[ -x /usr/sbin/riak ]]; then
  export RIAK=/usr/sbin/riak
else
  export RIAK=$RIAK_HOME/bin/riak
fi
export RIAK_CONF=/etc/riak/riak.conf
export USER_CONF=/etc/riak/user.conf
export RIAK_ADVANCED_CONF=/etc/riak/advanced.config
export SCHEMAS_DIR=/usr/lib/riak/share/schema/
export RIAK_ADMIN="$RIAK admin"

# Set ports for PB and HTTP
export PB_PORT=${PB_PORT:-8087}
export HTTP_PORT=${HTTP_PORT:-8098}

# Use ping to discover our HOSTNAME because it's easier and more reliable than other methods
export HOST=${NODENAME:-$(hostname -f)}
export HOSTIP=$(hostname -i)
# CLUSTER_NAME is used to name the nodes and is the value used in the distributed cookie
export CLUSTER_NAME=${CLUSTER_NAME:-riak}

# The COORDINATOR_NODE is the first node in a cluster to which other nodes will eventually join
export COORDINATOR_NODE=${COORDINATOR_NODE:-$HOSTNAME}
export COORDINATOR_NODE_HOST=$(ping -c1 $COORDINATOR_NODE | awk '/^PING/ {print $3}' | sed -e 's/[()]//g' -e 's/:$//') || '127.0.0.1'

sleep 10
# Run all prestart scripts
PRESTART=$(find /etc/riak/prestart.d -name *.sh -print | sort)
for s in $PRESTART; do
  . $s
done

sleep 10

$RIAK start &

sleep 40

# join cluster if needed
if [[ -z "$($RIAK_ADMIN cluster status | egrep $COORDINATOR_NODE)" && "$COORDINATOR_NODE" != "$HOST" ]]; then
  echo "Connecting to cluster coordinator $COORDINATOR_NODE"
  riak admin cluster join $CLUSTER_NAME@$COORDINATOR_NODE
  riak admin cluster plan
  riak admin cluster commit
fi