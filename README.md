CassandraTestEnv
================

A simple vagrant-based Test-Environment of a 4-node-Cassandra-Cluster.

#Fetching Ressources

First of all, we need a JDK (here: JDK 8) and Apache Cassandra. To fetch the ressources and persist them use:
```
./bin/fetchRessources.sh
```

#Startup
To initialize the vagrant boxes and startup the cassandra cluster:
```
cd cassandra
vagrant up
```
This will fetch the Ubuntu 14.04. image if not exist, start all nodes (node 1-4) and install them with all neccessary stuff.

The single boxes are named node1, node2, node3 and finally node4.
(node1 and node2 are configured as cassandra seed instances)
In case, you'll have to startup a single instance, you can use:
```
vagrant up <node-name>
```
#Working
To connect to a single instance, you'll have to use:
```
vagrant ssh <node-name>
```

To check, if everything's fine with the cluster, try:
```
nodetool status
```
on any box.

To restart a single cassandra instance, use:
```
/etc/init.d/cassandra stop|start|restart
```

Enjoy C* !
