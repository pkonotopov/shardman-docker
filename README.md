[![Docker Repository on Quay](https://quay.io/repository/kakoka/shardman/status "Docker Repository on Quay")](https://quay.io/repository/kakoka/shardman) [![GitHub tag](https://badgen.net/github/tag/pkonotopov/shardman-docker)](https://github.com/pkonotopov/shardman-docker/tags)

<h1>Shardman in docker</h1>

* Clone repo: `git clone git@github.com:pkonotopov/shardman-docker.git shardman`
* Latest Shardman documentation: [http://repo.postgrespro.ru/doc/pgprosm/14.5.1/en/html](http://repo.postgrespro.ru/doc/pgprosm/14.5.1/en/html)
* Inital cluster config in [spec.json](conf/spec.json) file: one sard node, no replication, no monitor. 
* Inital cluster config with shards replication [spec-replication.json](conf/spec-replication.json) file: every shard has replica, monitor enabled. 
* Inital cluster config with Shardman transport enabled [spec-silk.json](conf/spec-silk.json) file: one sard node, no replication, no monitor. 
* Limitations:
  * Linux systems Ubuntu/Centos/MacOS - tested.
  * For MacOS see the chapter #9 - [Run containers with the systemd on MacOS](#9-run-containers-with-systemd-on-macos).
  * WSL/WSL2 - not tested.

- [1. Quck start](#1-quck-start)
- [2. Quck build your own image](#2-quck-build-your-own-image)
- [3. Simple Shardman cluster](#3-simple-shardman-cluster)
  - [3.1 Up](#31-up)
  - [3.2 Initialization](#32-initialization)
  - [3.3 Get hostname of the first node](#33-get-hostname-of-the-first-node)
  - [3.4 Add first node to the cluster](#34-add-first-node-to-the-cluster)
  - [3.5 Connect to the cluster](#35-connect-to-the-cluster)
- [4. Scale up](#4-scale-up)
  - [4.1 Create new containers](#41-create-new-containers)
  - [4.2 Get containers hostnames](#42-get-containers-hostnames)
  - [4.3 Add new nodes to cluster](#43-add-new-nodes-to-cluster)
- [5. Scale down](#5-scale-down)
  - [5.1 Remove nodes from the cluster configuration:](#51-remove-nodes-from-the-cluster-configuration)
  - [5.2 Remove containers](#52-remove-containers)
- [6. Create cluster with shard replicas](#6-create-cluster-with-shard-replicas)
- [7. Expose ports to all cluster nodes with Traefik (Load Balancing, port 8432)](#7-expose-ports-to-all-cluster-nodes-with-traefik-load-balancing-port-8432)
- [8. Logging](#8-logging)
- [9. Run containers with systemd on MacOS](#9-run-containers-with-systemd-on-macos)
- [10. Build your own docker image](#10-build-your-own-docker-image)
  - [10.1 Intel chip](#101-intel-chip)
  - [10.2 Apple M1](#102-apple-m1)

After cloning shardman-docker repo please execute these steps.

## 1. Quck start

```shell
docker compose -f docker-compose.yml up -d --scale shards=3 --no-recreate
docker exec sdm_shard_1 shardmanctl init -f /etc/shardman/spec.json
docker exec sdm_shard_1 shardmanctl nodes add -n $(docker ps --filter "label=com.shardman.role=shard" -aq | awk '{aggr=aggr $1","} END {print aggr}' | rev | cut -c 2- | rev)

# Connect to database
psql -h 127.1 -U postgres

```

## 2. Quck build your own image

```shell
docker buildx build --platform linux/amd64 --tag <image name>:<tag> . -f Dockerfile
```

## 3. Simple Shardman cluster

In this configuration **only the first cluster node** will be accessible from outside: `sdm_shard_1`, port `5432`.

Docker compose project name located in [.env](.env) file:

```shell
COMPOSE_PROJECT_NAME=sdm
COMPOSE_COMPATIBILITY=true
```

### 3.1 Up

```shell
docker-compose -f docker-compose.yml up -d
```

This command bring up three containers: `sdm_etcd_1` and `sdm_shard_1`, `sdm_shards_1` in simple configuration without additional nodes, replicas and monitor.

### 3.2 Initialization

```shell
docker exec sdm_shard_1 shardmanclt init -f /etc/shardman/spec.json
```

This command uploads initial configuraion into the etcd k/v storage.

### 3.3 Get hostname of the first node

```shell
docker ps --filter "label=com.shardman.role=shard" -aq --format "table {{.ID}} {{.Names}}"
```

The expected output: 

```shell
dd47ba86b46c sdm_shards_1
85457103f6aa sdm_shard_1
```

**sdm_shard_1** - this node we will add as a first cluster node. 

### 3.4 Add first node to the cluster

```shell
docker exec sdm_shard_1 shardmanctl nodes add -n 85457103f6aa
```

### 3.5 Connect to the cluster

```shell
psql -h 127.0.0.1 -p 5432 -U postgres
```

## 4. Scale up
### 4.1 Create new containers

```shell
docker-compose -f docker-compose-one-node.yml up -d --scale shards=3 --no-recreate
```

### 4.2 Get containers hostnames

```shell
docker ps --filter "label=com.shardman.role=shard" -a --format "table {{.ID}} {{.Names}}"
```

Expected output:

```shell
CONTAINER ID NAMES
ba2e956b5095 sdm_shards_1
d500d2c70b3e sdm_shards_2
5c42f00bca5a sdm_shards_3
2ca4e1984120 sdm_shard_1
```

**Containers ID's** are the hostnames of new containers, so let's add these new hosts to the cluster:

### 4.3 Add new nodes to cluster

```shell
docker exec sdm_shard_1 shardmanctl nodes add -n ba2e956b5095,d500d2c70b3e,5c42f00bca5a
```

## 5. Scale down
### 5.1 Remove nodes from the cluster configuration:

```shell
docker exec sdm_shard_1 shardmanctl nodes rm -n ba2e956b5095,d500d2c70b3e,5c42f00bca5a
```

### 5.2 Remove containers

```shell
docker-compose up --scale shards=1 --no-recreate -d
```

## 6. Create cluster with shard replicas
If you want to create cluster with replicas and monitors you should change some parameters in the specification file [spec.json](conf/spec.json):

```json
{
...
"Repfactor": 1,
"MonitorsNum": 1
...
}
```

or use the prepared [spec-replication.json](conf/spec-replication.json) file.
If you want to change any cluster parameters you can make changes in the `spec.json` file.
Then at the Up step (1.1) run cluster with minimal nodes count 2. We are using 4 shards: 

```shell
docker-compose -f docker-compose.yml up -d --no-recreate
```

At the Initialization step (1.2) upload configuration file into the etcd k/v store.
Finally, add two created nodes to the cluster. By default docker compose creates two containers with Shardaman. If you want more shards, use `scale` option, for example – `--scale shards=3 --no-recreate`. 

Get nodes names:

```shell
docker ps --filter "label=com.shardman.role=shard" -aq
```

The expected output should be:

```shell
2ca4e1984120
5c42f00bca5a
```

Add nodes: 

```shell
docker exec sdm_shard_1 shardmanctl nodes add -n 2ca4e1984120,5c42f00bca5a
```

## 7. Expose ports to all cluster nodes with Traefik (Load Balancing, port 8432)
Create cluster with predifined count of nodes:

```shell
docker-compose -f docker-compose-traefik.yml up -d --scale shard=4
```

Create configuration and add nodes to the cluster:

- [spec.json](conf/spec.json) - simple Shardman cluster configuration _without_ shard replication (HA)
- [spec-replication.json](conf/spec-replication.json) simple Shardman cluster configuration _with_ shard replication (HA)
- [spec-silk.json](conf/spec-silk.json) - simple Shardman cluster configuration _without_ shard replication (HA) and with shardman transport enabled -[A New Approach to Sharding for Distributed PostgreSQL](https://postgrespro.com/blog/pgsql/5969681)

Pick configuration you want. For the local deployment (i.e. docker compose) we recomend to use shards _without_ replication.

```shell
docker exec sdm_shard_1 shardmanctl init -f /etc/shardman/spec.json

docker exec sdm_shard_1 shardmanctl nodes add -n $(docker ps --filter "label=com.shardman.role=shard" -aq | awk '{aggr=aggr $1","} END {print aggr}' | rev | cut -c 2- | rev)

2022-09-16T09:02:18.306Z	INFO	ladle/ladle.go:387	Checking if shardmand on all nodes have applied current cluster configuration
2022-09-16T09:02:18.308Z	INFO	ladle/ladle.go:414	Initting Stolon instances...
2022-09-16T09:02:19.214Z	INFO	ladle/ladle.go:498	Waiting for Stolon daemons to start... make sure shardmand daemons are running on the nodes
.........................................
2022-01-13T11:59:25.820Z	INFO	ladle/ladle.go:559	Adding repgroups...
.........................................
2022-01-13T11:59:39.252Z	INFO	ladle/ladle.go:586	Successfully added nodes b0e479b46867, 64f3d9a22fca, 7eab74c472a6, 9933d8eeef9a to the cluster

psql -h 127.0.0.1 -p 8432 -U postgres
select pgpro_version();
                                                    pgpro_version
---------------------------------------------------------------------------------------------------------------------
 PostgresPro (shardman) 14.5.1 on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 9.4.0-1ubuntu1~20.04.1) 9.4.0, 64-bit
```

Delete all containers, before re-run after major changes:
```shell
docker-compose down
```

Scale up and scale down is the similar as described above.

Scale up: 

```shell
docker-compose -f docker-compose-traefik.yml up --scale shard=8
```

then get nodes names and add them to Shardman cluster.

Scale down: firstly, remove nodes from the cluster

```shell
docker exec sdm_shard_1 shardmanctl nodes rm -n node_name_1,node_name_2,...
```

then run 

```shell
docker-compose -f docker-compose-traefik.yml up --scale shard=2
```

Nodes automatically adding and removing from/to Traefik Load Balancer.

Traefik uses **round robin** to balance connections to cluster nodes. 
So every new connection attempt connects the client to the **next node** in cluster.

Login into Traefik Web UI - `http://localhost:8080`. Login/password: admin/passsword.

## 8. Logging

To get logs from needed shard:

```shell
docker exec -it sdm_shard_1 journalctl -f
```

To configure PostgreSQL logging please make changes in [spec](conf/spec.json) - `pgParameters` section before cluster initialization (`shardman-ladel init`).

## 9. Run containers with systemd on MacOS

```shell 
# Stop running Docker on Mac
test -z "$(docker ps -q 2>/dev/null)" && osascript -e 'quit app "Docker"'

# Install jq and moreutils so we can merge into the existing json file
brew install jq moreutils

# Add the needed cgroup config to docker settings.json
echo '{"deprecatedCgroupv1": true}' | \
  jq -s '.[0] * .[1]' ~/Library/Group\ Containers/group.com.docker/settings.json - | \
  sponge ~/Library/Group\ Containers/group.com.docker/settings.json

# Restart docker desktop
open --background -a Docker
```

## 10. Build your own docker image

Only x86 architecture is supported. Build is simple:

### 10.1 Intel chip
<pre>
docker build --tag my-shardman-image:b01 . -f Dockerfile
</pre>

### 10.2 Apple M1

Need to define target architecture `--platform linux/amd64`.
<pre>
docker buildx build --platform linux/amd64 --tag my-shardman-image:b01 . -f Dockerfile
</pre>

Then put the new image name into your docker compose file.