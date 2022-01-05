# MySQL Replica Mode
## Create network if not is exists
```
docker network create network-dev
```
## Run with replica
```shell
docker-compose up -d
./setup-replica.sh
```