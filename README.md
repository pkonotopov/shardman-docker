# Shardman docker compose.

* Shardman documentation: [http://repo.postgrespro.ru/doc/pgprosm/14beta2.1/en/html](http://repo.postgrespro.ru/doc/pgprosm/14beta2.1/en/html)
* Clone repo: `git clone git@github.com:pkonotopov/shardman-docker.git shardman`
* Limitations:
  * Linux systems Ubuntu/Centos/Debian - tested.
  * For MacOS see the chapter #7 - how to run docker container with the systemd inside.
  * WSL - not tested.
* Inital cluster config in [spec.json](conf/spec.json) file: one node, no replication, no monitor. 
* Inital cluster config with shards replication [spec_replication.json](conf/spec_replication.json) file: every shard has replica, monitor enabled. 

After cloning shardman-docker repo please execute these steps.

## 1. Simple launch Shardman in containers via docker-compose

Docker compose project name located in [.env](.env) file:
`COMPOSE_PROJECT_NAME=sdm`

### 1.1 Up

`docker-compose up -d`

This command bring up two containers: `etcd` and `shardman` in simple configuration without additional nodes, replicas and monitor.

### 1.2 Initialization of cluster configuration
`docker exec sdm_shard_1 shardman-ladle init -f /etc/shardman/spec.json`

This command uploads initial configuraion into the etcd storage.

### 1.3 Get name of the first shardman node
`docker ps --filter "label=com.shardman.role=shard" -aq`

The expected output should be like this: 
`2ca4e1984120`

#### 1.4 Add first node to the cluster
`docker exec sdm_shard_1 shardman-ladle addnodes -n 2ca4e1984120`

## 2. Cluster scale up
### 2.1 Add new containers
`docker-compose up --scale shard=4 --no-recreate -d`

### 2.2 Get hostnames
`docker ps --filter "label=com.shardman.role=shard" -a --format "table {{.ID}} {{.Names}}"`
Expected output:
```
CONTAINER ID NAMES
ba2e956b5095 sdm_shard_1
d500d2c70b3e sdm_shard_2
5c42f00bca5a sdm_shard_3
2ca4e1984120 sdm_shard_4
```
Containers ID's are the hostnames of new containers, so add new hosts to the cluster:

### 2.3 Add nodes to cluster
`docker exec sdm_shard_1 shardman-ladle addnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

## 3. Cluster scale down
### 3.1 Remove nodes from the cluster configuration:
`docker exec sdm_shard_1 shardman-ladle rmnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

### 3.2 Remove containers
`docker-compose up --scale shard=1 --no-recreate -d`

## 4. Create cluster with shard replicas
If you want to create cluster with replicas and monitors you should change some parameters in the specification file [spec.json](conf/spec.json):

```
"Repfactor": 1
"MonitorsNum": 1
```

or use the prepared [spec_replication.json](conf/spec_replication.json) file.
Then at the Up step (1.1) run cluster with minimal nodes count 2: `docker-compose up --scale shard=2 -d`.
At the Initialization step (1.2) upload configuration file into etcd k/v store.
Finally, add two created nodes to the cluster.
Get nodes names: 
`docker ps --filter "label=com.shardman.role=shard" -aq`
The expected output should be: 
```
2ca4e1984120
5c42f00bca5a
```
Add nodes: `docker exec sdm_shard_1 shardman-ladle addnodes -n 2ca4e1984120,5c42f00bca5a`.

## 5. Expose ports to cluster nodes with Traefik (Load Balancing, port 8432)
Create cluster with predifined count of nodes:

`docker-compose -f docker-compose-traefik.yml up -d --scale shard=4`

Create configuration and add nodes to the cluster:

- [spec.json](conf/spec.json) - simple Shardman cluster configuration _without_ shard replication (HA)
- [spec_replication.json](conf/spec_replication.json) simple Shardman cluster configuration _with_ shard replication (HA)

Pick configuration you want. For the local deployment (i.e. docker compose) we recomend to use shards _without_ replication.

<pre>
$ docker exec sdm_shard_1 shardman-ladle init -f /etc/shardman/spec.json

$ docker exec sdm_shard_1 shardman-ladle addnodes -n $(docker ps --filter "label=com.shardman.role=shard" -aq | awk '{aggr=aggr $1","} END {print aggr}' | rev | cut -c 2- | rev)

2022-01-13T11:58:54.534Z	INFO	ladle/ladle.go:372	Checking if bowls on all nodes have applied current cluster configuration
2022-01-13T11:58:54.536Z	INFO	ladle/ladle.go:399	Initting Stolon instances...
2022-01-13T11:58:54.640Z	INFO	ladle/ladle.go:483	Waiting for Stolon daemons to start... make sure bowl daemons are running on the nodes
2022-01-13T11:59:25.820Z	INFO	ladle/ladle.go:559	Adding repgroups...
2022-01-13T11:59:39.252Z	INFO	ladle/ladle.go:586	Successfully added nodes b0e479b46867, 64f3d9a22fca, 7eab74c472a6, 9933d8eeef9a to the cluster

$ psql -h 127.0.0.1 -p 8432 -U postgres
</pre>

Scale up and scale down is the similar as described above.

Scale up: `docker-compose -f docker-compose-traefik.yml up --scale shard=8`, then get nodes names and add them to Shardman cluster.
Scale down: firstly remove nodes from the cluster

```
docker exec sdm_shard_1 shardman-ladle rmnodes -n node_name_1,node_name_2,...
```

, then run `docker-compose -f docker-compose-traefik.yml up --scale shard=2`.

Nodes automatically adding and removing from/to Traefik Load Balancer.

Traefik uses _round robin_ to balance connections to cluster nodes. So every new connection attempt connects the client to the next node in cluster.

Login into Traefik UI - `http://localhost:8080`. Login/password: admin/passsword.

## 6. Expose ports to only first cluster node (shard-1, port 5432)

In this configuration you can have access to the cluster thru one node (shard-1). Other shards also will be operable, but without direct access to them. 

Create cluster with predifined count of nodes (4 nodes: shard-1, shards-1,2,3):

`docker-compose -f docker-compose-one-node.yml up -d --scale shards=3`

Create configuration and add nodes to the cluster:

- [spec.json](conf/spec.json) - simple Shardman cluster configuration _without_ shard replication (HA)
- [spec_replication.json](conf/spec_replication.json) simple Shardman cluster configuration _with_ shard replication (HA)

Pick configuration you want. For the local deployment (i.e. docker compose) we recomend to use shards _without_ replication.

<pre>
$ docker exec sdm_shard_1 shardman-ladle init -f /etc/shardman/spec.json

$ docker exec sdm_shard_1 shardman-ladle addnodes -n $(docker ps --filter "label=com.shardman.role=shard" -aq | awk '{aggr=aggr $1","} END {print aggr}' | rev | cut -c 2- | rev)

$ psql -h 127.0.0.1 -p 5432 -U postgres
</pre>
Scale up and scale down is the similar as described above (in section 5).

#### 6.1 Logging
To get logs from needed shard:
```
docker exec -it sdm_shard_1 journalctl -f
```
To configure PostgreSQL logging please make changes in [spec](conf/spec.json) - `pgParameters` section before cluster initialization (`shardman-ladel init`).

## 7. Run containers with systemd on MacOS
### 7.1 Stop running Docker on Mac
`test -z "$(docker ps -q 2>/dev/null)" && osascript -e 'quit app "Docker"'`
### 7.2 Install jq and moreutils so we can merge into the existing json file
`brew install jq moreutils`
### 7.3 Add the needed cgroup config to docker settings.json
```
echo '{"deprecatedCgroupv1": true}' | \
  jq -s '.[0] * .[1]' ~/Library/Group\ Containers/group.com.docker/settings.json - | \
  sponge ~/Library/Group\ Containers/group.com.docker/settings.json
```
### 7.4 Restart docker desktop
`open --background -a Docker`

## 8. Build your own docker image
It's simple:
### 8.1 Intel chip
<pre>
docker build --tag my-shardman-image:b01 . -f Dockerfile
</pre>

### 8.2 Apple M1
<pre>
docker buildx build --platform linux/amd64 --tag my-shardman-image:b01 . -f Dockerfile
</pre>

Then put the new image name into your docker compose file.