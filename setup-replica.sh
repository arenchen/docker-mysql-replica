#!/usr/bin/env bash

MYSQL_ROOT_PASSWORD=`docker exec mysql printenv MYSQL_ROOT_PASSWORD`
echo "PWD: $MYSQL_ROOT_PASSWORD"

echo "Waitting master is ready to accept connections"
docker exec -t mysql bash -c 'while ! mysqladmin --port=3306 --password='$MYSQL_ROOT_PASSWORD' ping >/dev/null 2>&1; do sleep 5; done'
echo "Create user 'replicator'"
docker exec -t mysql mysql -p$MYSQL_ROOT_PASSWORD -e "GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;"
docker exec -t mysql mysql -p$MYSQL_ROOT_PASSWORD -e "select Host,User from mysql.user;"
docker exec -t mysql bash -c 'cat > /etc/mysql/conf.d/master.cnf << EOF
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-ignore-db=mysql
# binlog-do-db
# binlog_format=mixed
EOF'

echo "Waitting replica is ready to accept connections"
docker exec -t mysql-replica bash -c 'while ! mysqladmin --port=3306 --password='$MYSQL_ROOT_PASSWORD' ping >/dev/null 2>&1; do sleep 5; done'
echo "Change replica master host"
docker exec -t mysql-replica mysql -p$MYSQL_ROOT_PASSWORD -e "CHANGE MASTER TO MASTER_HOST='mysql', MASTER_USER='repl', MASTER_PASSWORD='$MYSQL_ROOT_PASSWORD';start slave;"
docker exec -t mysql-replica bash -c 'cat > /etc/mysql/conf.d/slave.cnf << EOF
[mysqld]
server-id=2
# relay_log = relay_bin
# relay-log-index = relay-bin.index
read-only=1
EOF'
docker-compose restart