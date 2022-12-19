### Percona Group Replication

This compose file and scripts are for setting up percona server 8 mysql group replication using proxysql on the docker environment. This will setup 3 percona server and 1 proxysql container with the following container and hostnames in docker environment:

```
percona1
percona2
percona3
proxysql
```

Steps:

1. Setup the environment file and change the mysql root passwords in the .env file
```bash
- cp dot.env .env 
```

2. Initialize the db cluster. This will create persist3nt db files in the App/ folder in the current directory.
```bash
# docker compose up db-init
```

3. Stop the databases after initialization
```bash
# docker compose down --remove-orphans
```

4. Start the cluster by mounting the spesific parameters in Config/ directory
```bash
# docker compose up db-cluster
```

5. Run the cluster migration script which setup percona-server and proxysql configuration respectively according to [percona configuration instructions](https://docs.percona.com/percona-distribution-for-mysql/8.0/deploy-pdps-group-replication.html)

```bash
# bash percona_replication_setup.sh
````

6. You can reach the nodes by 

`docker exec -it percona1 mysql -u root -p<PassWordHere> -h 127.0.0.1`

or by exposed ports from hosts:
```
percona1 -> 3306:
percona2 -> 3307:
percona3 -> 3308:
```

If you need to start over, bring the cluster down by `docker compose down --remove-orphans` command and deleting the directory Apps/ in the folder 




