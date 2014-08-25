#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CASSANDRA_PKG=apache-cassandra-2.0.9-bin.tar.gz
JDK_PKG=jdk-8u20-linux-x64.tar.gz

CASSANDRA_URL=http://mirrors.koehn.com/apache/cassandra/2.0.9/${CASSANDRA_PKG}
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u20-b26/${JDK_PKG}

CURL=`which curl`

function checkCurl {
  if [ -z ${CURL} ] ; then
    echo "Please install curl and put it in your PATH."
    exit 3
  fi
}

function initOpsCenter {
  echo "deb http://debian.datastax.com/community stable main" | \
    sudo tee -a /etc/apt/sources.list.d/datastax.community.list
  curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install -y opscenter
  sudo service opscenterd start
}

function getJava {
  checkCurl
  ${CURL} -o ${REPOSITORY_DIR}/${JDK_PKG} -b oraclelicense=accept-securebackup-cookie -O -L ${JDK_URL}
}

function getCassandra {
  checkCurl
  ${CURL} -o ${REPOSITORY_DIR}/${CASSANDRA_PKG} ${CASSANDRA_URL}
}

function initJava {
  sudo tar xvfz ${REPOSITORY_DIR}/${JDK_PKG} -C /opt/
  sudo ln -s /opt/jdk1.8.0_20 /opt/java
  sudo chown -R root. /opt/jdk1.8.0_20
  sudo cp ${REPOSITORY_DIR}/java.sh /etc/profile.d/

  sudo update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1
  sudo update-alternatives --install "/usr/bin/javac" "javac" "/opt/java/bin/javac" 1
  sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/opt/java/bin/javaws" 1
  sudo update-alternatives --set java /opt/java/bin/java
  sudo update-alternatives --set javac /opt/java/bin/javac
  sudo update-alternatives --set javaws /opt/java/bin/javaws

  . /etc/profile
}

function initCassandra {
  sudo tar xvfz ${REPOSITORY_DIR}/${CASSANDRA_PKG} -C /opt/
  sudo ln -s /opt/apache-cassandra-2.0.9 /opt/cassandra

  if [ ! -e /etc/init.d/cassandra ] ; then
    sudo cp ${REPOSITORY_DIR}/init-cassandra /etc/init.d/cassandra
    sudo chown root. /etc/init.d/cassandra
    sudo chmod +x /etc/init.d/cassandra
  fi

  sudo cp ${REPOSITORY_DIR}/cassandra.yaml /opt/cassandra/conf/
  sudo sed -i.bak -e "s/\${ip_addr}/${IP_ADDRESS}/g" /opt/cassandra/conf/cassandra.yaml

  sudo cp ${REPOSITORY_DIR}/cassandra-rackdc.properties /opt/cassandra/conf/
  sudo sed -i.bak -e "s/\${datacenter}/${DATACENTER}/g" \
    /opt/cassandra/conf/cassandra-rackdc.properties

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
  sudo cp ${REPOSITORY_DIR}/cassandra.sh /etc/profile.d/

  . /etc/profile
  sudo update-rc.d cassandra defaults
  sudo service cassandra restart
}
