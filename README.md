CassandraTestEnv
================

A simple vagrant-based Test-Environment of a 4-node-Cassandra-Cluster and a separate box for the Datastax OpsCenter.

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
This will fetch the Ubuntu 14.04. image if not exist, start all nodes (ops and node 1-4) and install them with all neccessary stuff.

The single boxes are named ops, node1, node2, node3 and finally node4.
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

##Cassandra Boxes
To check, if everything's fine with the cluster, try:
```
nodetool status
```
on any box.

To restart a single cassandra instance, use:
```
/etc/init.d/cassandra stop|start|restart
```

##OPSCenter
The port of the OPSCenter - 8888 - is forwarded to the host.
To open the OPSCenter use a local browser:
```
http://localhost:8888
```
If you call the OPSCenter the first time, you'll have to configure the existing Cluster.
Therefore choose 'manage an existing cluster' at the 1st dialog and use an IP of the cluster (i.e. 192.168.2.110).
After that you'll have to install the agents. (Use the 'fix' link at the top of the dashboard).
The Credentials of the needed ssh-users are vagrant/vagrant.

Enjoy C* !
