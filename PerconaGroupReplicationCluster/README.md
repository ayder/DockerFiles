### Percona Group Replication Test Setup

This compose file and scripts are for setting up percona server version 8.0.23 with mysql group replication using proxysql as HA on the docker environment. This will setup 3 percona  and 1 proxysql containers with the following host/container names in docker environment:

```
percona1
percona2
percona3
proxysql
```

Follow the steps after cloning this content into a directory:

1. Setup the environment file and change the mysql root passwords in the .env file
```bash
- cp dot.env .env 
```

2. Initialize the db cluster. This will create persistent db files in the App/ folder in the current directory.
```bash
# docker compose up db-init
```

3. Stop the databases after initialization
```bash
# docker compose down --remove-orphans
```

4. Start the cluster by mounting the spesific parameters from the Config/ directory for each service.
```bash
# docker compose up db-cluster
```

5. Run the cluster migration script which setup percona-server and proxysql configuration respectively according to [percona product documentation](https://docs.percona.com/percona-distribution-for-mysql/8.0/deploy-pdps-group-replication.html)

```bash
# bash percona_replication_setup.sh
````

6. You can reach mysql and proxysql services on the nodes by 

`docker exec -it percona1 mysql -u root -p<PassWordHere> -h 127.0.0.1`
`docker exec -it proxysql mysql -uadmin  -padmin -h 127.0.0.1 -P 6032`

or by exposed ports from hosts:
```
mysqlsh -uroot -p<PassWordHere> -h 127.0.0.1 -P 3306     # percona1
mysqlsh -uroot -p<PassWordHere> -h 127.0.0.1 -P 3307     # percona2
mysqlsh -uroot -p<PassWordHere> -h 127.0.0.1 -P 3308     # percona3
```

If you need to start over, bring the cluster down by `docker compose down --remove-orphans` command and deleting the directory Apps/ in the folder.




