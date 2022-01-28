# Shardman docker compose.

* Shardman documentation: [http://repo.postgrespro.ru/doc/pgprosm/14beta2.1/en/html](http://repo.postgrespro.ru/doc/pgprosm/14beta2.1/en/html)
* Clone repo: `git clone git@github.com:pkonotopov/shardman-docker.git shardman`
* Limitations: Linux systems only. No MacosX and WSL supported.
* Inital cluster config in [spec.json](conf/spec.json) file: one node, no replication, no monitor. 

After cloning shardman-docker repo please execute these steps.

## 1. Launch Shardman in containers via docker-compose

### 1.1 Up

`docker-compose up -d`

This command bring up two containers: `etcd` and `shardman` in simple configuration without additional nodes, replicas and monitor.

### 1.2 Initialization of cluster configuration
`docker exec shardman_shard_1 shardman-ladle init -f /etc/shardman/spec.json`

This command uploads initial configuraion into the etcd storage.

### 1.3 Get name of the first shardman node
`docker ps --filter "label=com.shardman.role=shard" -aq`

The expected output should be like this: 
`2ca4e1984120`

#### 1.4 Add first node to the cluster
`docker exec shardman_shard_1 shardman-ladle addnodes -n 2ca4e1984120`

## 2. Cluster scale up

### 2.1 Add new containers
`docker-compose up --scale shard=4 --no-recreate -d`

### 2.2 Get hostnames
`docker ps --filter "label=com.shardman.role=shard" -a --format "table {{.ID}} {{.Names}}"`

Expected output:
```
CONTAINER ID NAMES
ba2e956b5095 shardman_shard_4
d500d2c70b3e shardman_shard_3
5c42f00bca5a shardman_shard_2
2ca4e1984120 shardman_shard_1
```

Containers ID's are the hostnames of new containers, so add new hosts to the cluster:

### 2.3 Add nodes to cluster
`docker exec shardman_shard_1 shardman-ladle addnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

## 3. Cluster scale down

### 3.1 Remove nodes from the cluster configuration:
`docker exec shardman_shard_1 shardman-ladle rmnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

### 3.2 Remove containers
`docker-compose up --scale shard=1 --no-recreate -d`

## 4. Create cluster with shard replicas

If you want to create cluster with replicas and monitors you should change some parameters in the specification file [spec.json](conf/spec.json):

```
"Repfactor": 1
"MonitorsNum": 1
```

Then at the Up step (1.1) run cluster with minimal nodes count 2: `docker-compose up --scale shard=2 -d`.

At the Initialization step (1.2) upload configuration file into etcd k/v store.

Finally, add two created nodes to the cluster.

Get nodes names: `docker ps --filter "label=com.shardman.role=shard" -aq`

The expected output should be: 
```
2ca4e1984120
5c42f00bca5a
```

Add nodes: `docker exec shardman_shard_1 shardman-ladle addnodes -n 2ca4e1984120,5c42f00bca5a`.

## 5. Expose ports to cluster nodes with Traefik (Load Balancing, port 8432)

Create cluster with predifined count of nodes:

`docker-compose -f docker-compose-traefik.yml up --scale shard=4`

Create configuration and add nodes to the cluster:

<pre>
$ docker exec shardman_shard_1 shardman-ladle init -f /etc/shardman/spec.json

$ docker exec shardman_shard_1 shardman-ladle addnodes -n $(docker ps --filter "label=com.shardman.role=shard" -aq | awk '{aggr=aggr $1","} END {print aggr}' | head -c-2)

2022-01-13T11:58:54.534Z	INFO	ladle/ladle.go:372	Checking if bowls on all nodes have applied current cluster configuration
2022-01-13T11:58:54.536Z	INFO	ladle/ladle.go:399	Initting Stolon instances...
2022-01-13T11:58:54.640Z	INFO	ladle/ladle.go:483	Waiting for Stolon daemons to start... make sure bowl daemons are running on the nodes
2022-01-13T11:59:25.820Z	INFO	ladle/ladle.go:559	Adding repgroups...
2022-01-13T11:59:39.252Z	INFO	ladle/ladle.go:586	Successfully added nodes b0e479b46867, 64f3d9a22fca, 7eab74c472a6, 9933d8eeef9a to the cluster

$ psql -h 127.0.0.1 -p 8432 -U postgres

psql (12.5, server 14.0)
WARNING: psql major version 12, server major version 14.
         Some psql features might not work.
Type "help" for help.

postgres=#
</pre>

Scale up and scale down is the similar as described above.

Scale up: `docker-compose -f docker-compose-traefik.yml up --scale shard=8`, then get nodes names and add them to Shardman cluster.
Scale down: firstly remove nodes from the cluster, then run `docker-compose -f docker-compose-traefik.yml up --scale shard=2`.

Nodes automatically adding and removing from/to Traefik Load Balancer.

Traefik uses round robin to balance connections to cluster nodes. So every new connection attempt connects client to next node in cluster.

Login into Traefik UI - `http://localhost:8080`. Login/password: admin/passsword.