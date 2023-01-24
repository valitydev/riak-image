#!/bin/bash
# Maybe join to a cluster
if [[ -z "$($RIAK_ADMIN cluster status | egrep $COORDINATOR_NODE)" && "$COORDINATOR_NODE" != "$HOST" ]]; then
  # Not already in this cluster, so join
  echo "Connecting to cluster coordinator $COORDINATOR_NODE"
  $RIAK_ADMIN cluster join $CLUSTER_NAME@$COORDINATOR_NODE
  $RIAK_ADMIN cluster plan
  $RIAK_ADMIN cluster commit
fi
