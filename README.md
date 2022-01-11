# Shardman docker compose.

Limitations: Linux systems only. No MacosX, WSL supported.

Clone repo: `git clone git@github.com:pkonotopov/shardman-docker.git shardman`

After cloning shardman-docker repo please follow these steps.
## 1. Launch Shardman in containers via docker-compose
### 1.1 Up

`docker-compose up -d` - this command bring up two containers: etcd and shardman in simple configuration (without additional nodes and replicas).

### 1.2 Init cluster
`docker exec shardman_shard_1 shardman-ladle init -f /etc/shardman/spec.json` - this command uploads initial configuraion into the etcd storage.

### 1.3 Get name of the first shardman node
`docker ps --filter "label=com.shardman.role=shard" -aq`
The expected output should be smth like this: `2ca4e1984120`

#### 1.4 Add first node to the cluster
`docker exec shardman_shard_1 shardman-ladle addnodes -n 2ca4e1984120`

## 2. Scale up cluster
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

`docker exec shardman_shard_1 shardman-ladle addnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

## 3. Scale down cluster

### 3.1 Remove nodes from the cluster configuration:
`docker exec shardman_shard_1 shardman-ladle rmnodes -n 5c42f00bca5a,d500d2c70b3e,ba2e956b5095`

### 3.2 Remove containers
`docker-compose up --scale shard=1 --no-recreate -d`
