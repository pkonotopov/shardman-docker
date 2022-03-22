#!/bin/bash
# put here etcd cluster endpoints, define etcd API version

export ETCDCTL_ENDPOINTS=http://etcd:2379
export ETCDCTL_API=v3

# install etcd cli utility
apt update
apt install etcd-client

# get all keys
etcdctl get "" --prefix

# Export from etcd Stolon config
etcdctl get --print-value-only shardman/cluster0/clusterdata   | jq .Spec.StolonSpec > stolon.json


@ curl -L http://etcd:2379/v2/keys/stolon


