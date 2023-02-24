#!/bin/bash

USER=root

if [ ! -f .env ]
then
  export $(cat .env | xargs)
fi


set -o noglob
GRANTS=$(cat <<EOF
SET SQL_LOG_BIN=0;
CREATE USER 'replica'@'%' IDENTIFIED WITH sha256_password BY 'replicapw'; 
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
create user monitor@'%' identified by 'monitor';
grant usage on *.* to 'monitor'@'%';
grant select on sys.* to 'monitor'@'%';
create user proxysql_writer@'%' identified by 'proxysql';
grant all privileges on *.* to proxysql_writer@'%';
create user proxysql_reader@'%' identified by 'proxysql';
grant all privileges on *.* to proxysql_reader@'%';
FLUSH PRIVILEGES;
SET SQL_LOG_BIN=1;
EOF
)


for port in 3306 3307 3308
do
  echo "running grants sql on 127.0.0.1:${port}"
  echo $GRANTS| mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P ${port}
  mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P ${port} -e "CHANGE MASTER TO MASTER_USER='replica', MASTER_PASSWORD='replicapw' FOR CHANNEL 'group_replication_recovery';"

done

mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P 3306 -e "select * from performance_schema.replication_group_members\G"
sleep 3


echo "Bootstrapping the primary..."
mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P 3306 <<EOF
SET GLOBAL group_replication_bootstrap_group=ON;
START GROUP_REPLICATION;
SET GLOBAL group_replication_bootstrap_group=OFF;
EOF
sleep 5

for port in 3307 3308
do
  echo "Joining secondary node .. ${port}"
  mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P ${port} -e "START GROUP_REPLICATION;"
  sleep 5

done

echo "Applying view to sys schema.."
mysqlsh -u${USER} -p${PASS} -h 127.0.0.1 -P 3306 < sys.gr_member_routing_candidate_status.sql
sleep 1


echo "Setting up proxysql.."

docker exec -i proxysql mysql -uadmin -padmin -h 127.0.0.1 -P 6032 <<EOF
set admin-hash_passwords='false';
save admin variables to disk;
load admin variables to runtime;
insert into mysql_users (username,password,default_hostgroup,comment) values ('proxysql_writer','proxysql',10,'application test user GR');
insert into mysql_users (username,password,default_hostgroup,comment) values ('proxysql_reader','proxysql',11,'application test user GR');
LOAD MYSQL USERS TO RUNTIME; 
SAVE MYSQL USERS TO DISK;
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections,comment) VALUES ('percona1',10,3306,10000,2000,'GR1');
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections,comment) VALUES ('percona2',10,3306,10000,2000,'GR1');
INSERT INTO mysql_servers (hostname,hostgroup_id,port,weight,max_connections,comment) VALUES ('percona3',10,3306,10000,2000,'GR1');
LOAD MYSQL SERVERS TO RUNTIME; 
SAVE MYSQL SERVERS TO DISK;
INSERT INTO mysql_group_replication_hostgroups (
writer_hostgroup,
backup_writer_hostgroup,
reader_hostgroup, 
offline_hostgroup,
active,
max_writers,
writer_is_also_reader,
max_transactions_behind)
values (
10,
12,
11,
9401,
1,
1,
0,
100);
LOAD MYSQL SERVERS TO RUNTIME; SAVE MYSQL SERVERS TO DISK;
EOF


sleep 10 
