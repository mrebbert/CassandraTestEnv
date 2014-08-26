#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CASSANDRA_USER="cassandra"
CASSANDRA_HOME="/opt/cassandra"
CASSANDRA_DATA_DIR="/var/lib/cassandra"
CASSANDRA_LOG_DIR="/var/log/cassandra"
CASSANDRA_VERSION="2.0.9"
CASSANDRA_PKG=apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz
CASSANDRA_URL=http://mirrors.koehn.com/apache/cassandra/${CASSANDRA_VERSION}/${CASSANDRA_PKG}

JAVA_HOME="/opt/java"
JDK_PKG=jdk-8u20-linux-x64.tar.gz
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
  sudo ln -s /opt/jdk1.8.0_20 ${JAVA_HOME}
  sudo chown -R root. /opt/jdk1.8.0_20
  sudo cp ${REPOSITORY_DIR}/java.sh /etc/profile.d/

  sudo update-alternatives --install "/usr/bin/java" "java" "${JAVA_HOME}/bin/java" 1
  sudo update-alternatives --install "/usr/bin/javac" "javac" "${JAVA_HOME}/bin/javac" 1
  sudo update-alternatives --install "/usr/bin/javaws" "javaws" "${JAVA_HOME}/bin/javaws" 1
  sudo update-alternatives --set java ${JAVA_HOME}/bin/java
  sudo update-alternatives --set javac ${JAVA_HOME}/bin/javac
  sudo update-alternatives --set javaws ${JAVA_HOME}/bin/javaws

  . /etc/profile
}

function initCassandra {
  sudo tar xvfz ${REPOSITORY_DIR}/${CASSANDRA_PKG} -C /opt/
  sudo ln -s /opt/apache-cassandra-${CASSANDRA_VERSION} ${CASSANDRA_HOME}

  if [ ! -e /etc/init.d/cassandra ] ; then
    sudo cp ${REPOSITORY_DIR}/init-cassandra /etc/init.d/cassandra
    sudo chown root. /etc/init.d/cassandra
    sudo chmod +x /etc/init.d/cassandra
  fi

  sudo cp ${REPOSITORY_DIR}/cassandra.yaml ${CASSANDRA_HOME}/conf/
  sudo sed -i.bak -e "s/\${ip_addr}/${IP_ADDRESS}/g" ${CASSANDRA_HOME}/conf/cassandra.yaml

  sudo cp ${REPOSITORY_DIR}/cassandra-rackdc.properties ${CASSANDRA_HOME}/conf/
  sudo sed -i.bak -e "s/\${datacenter}/${DATACENTER}/g" \
    ${CASSANDRA_HOME}/conf/cassandra-rackdc.properties

  if id -u ${CASSANDRA_USER} >/dev/null 2>&1; then
    echo "User ${CASSANDRA_USER} already exists."
  else
    sudo useradd -d ${CASSANDRA_HOME} ${CASSANDRA_USER}
  fi
  sudo chown -R ${CASSANDRA_USER}. ${CASSANDRA_HOME} 
  sudo chown -R ${CASSANDRA_USER}. /opt/apache-cassandra-${CASSANDRA_VERSION}

  if [ ! -e ${CASSANDRA_DATA_DIR} ] ; then
    sudo mkdir ${CASSANDRA_DATA_DIR}
    sudo chown ${CASSANDRA_USER}. ${CASSANDRA_DATA_DIR}
  fi

  if [ ! -e ${CASSANDRA_LOG_DIR} ] ; then
    sudo mkdir ${CASSANDRA_LOG_DIR}
    sudo chown ${CASSANDRA_USER}. ${CASSANDRA_LOG_DIR}
  fi
  sudo cp ${REPOSITORY_DIR}/cassandra.sh /etc/profile.d/

  . /etc/profile
  sudo update-rc.d cassandra defaults
  sudo service cassandra restart
}
