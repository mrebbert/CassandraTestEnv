#!/usr/bin/env bash

while getopts ":i:d:" opt; do
  case $opt in
    i)
      IP_ADDRESS=$OPTARG
      ;;
    d)
      DATACENTER=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ -z ${IP_ADDRESS} ] ; then
  echo "IP address is not set!"
  exit 1
fi

REPOSITORY_DIR="/var/repository"
JDK_PKG="jdk-8u20-linux-x64.tar.gz"
CASSANDRA_PKG="apache-cassandra-2.0.9-bin.tar.gz"

sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile

if [ "$HOSTNAME" = "ops" ] ; then
  if [ ! -e /etc/init.d/opscenterd ] ; then
    echo "deb http://debian.datastax.com/community stable main" | \
        sudo tee -a /etc/apt/sources.list.d/datastax.community.list
    curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y opscenter
    sudo service opscenterd start
  fi
  exit 0
fi

if [ -z ${DATACENTER} ] ; then
  echo "Datacenter name is not set!"
  exit 1
fi

if [ ! -e /opt/java  ] ; then

  if [ ! -e ${REPOSITORY_DIR}/${JDK_PKG} ] ; then
    echo "Please fetch the JDK-Package first. You can use the fetchRessource-Script in the bin directory."
    exit 1
  fi
  
  sudo tar xvfz ${REPOSITORY_DIR}/${JDK_PKG} -C /opt/
  sudo ln -s /opt/jdk1.8.0_20 /opt/java
  sudo chown -R root. /opt/jdk1.8.0_20
  sudo cp /var/repository/java.sh /etc/profile.d/

  sudo update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1
  sudo update-alternatives --install "/usr/bin/javac" "javac" "/opt/java/bin/javac" 1
  sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/java/bin/javaws" 1
  sudo update-alternatives --set java /opt/java/bin/java
  sudo update-alternatives --set javac /opt/java/bin/javac
  sudo update-alternatives --set javaws /opt/java/bin/javaws

  . /etc/profile
fi

if [ ! -e /opt/apache-cassandra-2.0.9 ] ; then
  if [ ! -e ${REPOSITORY_DIR}/${CASSANDRA_PKG} ] ; then
    echo "Please fetch the Cassandra-Package first. You can use the fetchRessource-Script in the bin directory."
    exit 1
  fi
  sudo tar xvfz ${REPOSITORY_DIR}/${CASSANDRA_PKG} -C /opt/
  sudo ln -s /opt/apache-cassandra-2.0.9 /opt/cassandra

  if [ ! -e /etc/init.d/cassandra ] ; then
    sudo cp /var/repository/init-cassandra /etc/init.d/cassandra
    sudo chown root. /etc/init.d/cassandra
    sudo chmod +x /etc/init.d/cassandra
  fi

  sudo cp /var/repository/cassandra.yaml /opt/cassandra/conf/
  sudo sed -i.bak -e "s/\${ip_addr}/${IP_ADDRESS}/g" /opt/cassandra/conf/cassandra.yaml

  sudo cp /var/repository/cassandra-rackdc.properties /opt/cassandra/conf/
  sudo sed -i.bak -e "s/\${datacenter}/${DATACENTER}/g" /opt/cassandra/conf/cassandra-rackdc.properties

  if id -u cassandra >/dev/null 2>&1; then
    echo "user exists"
  else
    sudo useradd -d /opt/cassandra cassandra
  fi
  sudo chown -R cassandra. /opt/cassandra 
  sudo chown -R cassandra. /opt/apache-cassandra-2.0.9

  if [ ! -e /var/lib/cassandra ] ; then
    sudo mkdir /var/lib/cassandra
    sudo chown cassandra. /var/lib/cassandra
  fi

  if [ ! -e /var/log/cassandra ] ; then
    sudo mkdir /var/log/cassandra
    sudo chown cassandra. /var/log/cassandra
  fi
  sudo cp /var/repository/cassandra.sh /etc/profile.d/
  
  . /etc/profile
  sudo update-rc.d cassandra defaults
  sudo service cassandra restart
fi

exit 0
