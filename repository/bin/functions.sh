#!/usr/bin/env bash

CASSANDRA_USER="cassandra"
CASSANDRA_HOME="/opt/cassandra"
CASSANDRA_DATA_DIR="/var/lib/cassandra"
CASSANDRA_LOG_DIR="/var/log/cassandra"
CASSANDRA_VERSION="2.0.9"
CASSANDRA_PKG="apache-cassandra-${CASSANDRA_VERSION}-bin.tar.gz"
CASSANDRA_URL="http://mirrors.koehn.com/apache/cassandra/${CASSANDRA_VERSION}/${CASSANDRA_PKG}"

JAVA_HOME="/opt/java"
JDK_PKG="jdk-8u20-linux-x64.tar.gz"
JDK_URL="http://download.oracle.com/otn-pub/java/jdk/8u20-b26/${JDK_PKG}"

PKG_DIR="${REPOSITORY_DIR}/pkg"
MODULES_DIR="${REPOSITORY_DIR}/modules"
CASSANDRA_MODULE_DIR="${MODULES_DIR}/cassandra"
JDK_MODULE_DIR="${MODULES_DIR}/jdk"

CURL=`which curl`

function checkCurl {
  if [ -z ${CURL} ] ; then
    echo "Please install curl and put it in your PATH."
    exit 3
  fi
}

function createPackageDir {
  if [ -e ${PKG_DIR} ] ; then
    mkdir -p ${PKG_DIR}
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
  ${CURL} -o ${PKG_DIR}/${JDK_PKG} -b oraclelicense=accept-securebackup-cookie -O -L ${JDK_URL}
}

function getCassandra {
  checkCurl
  ${CURL} -o ${PKG_DIR}/${CASSANDRA_PKG} ${CASSANDRA_URL}
}

function initJava {
  sudo tar xfz ${REPOSITORY_DIR}/pkg/${JDK_PKG} -C /opt/
  sudo ln -s /opt/jdk1.8.0_20 ${JAVA_HOME}
  sudo chown -R root. /opt/jdk1.8.0_20
  sudo cp ${JDK_MODULE_DIR}/java.sh /etc/profile.d/

  sudo update-alternatives --install "/usr/bin/java" "java" \
      "${JAVA_HOME}/bin/java" 1 >/dev/null
  sudo update-alternatives --install "/usr/bin/javac" "javac" \
      "${JAVA_HOME}/bin/javac" 1 >/dev/null 
  sudo update-alternatives --install "/usr/bin/javaws" "javaws" \
      "${JAVA_HOME}/bin/javaws" 1 >/dev/null
  sudo update-alternatives --set java ${JAVA_HOME}/bin/java >/dev/null
  sudo update-alternatives --set javac ${JAVA_HOME}/bin/javac >/dev/null
  sudo update-alternatives --set javaws ${JAVA_HOME}/bin/javaws >/dev/null

  . /etc/profile
}

function initCassandra {
  sudo tar xfz ${REPOSITORY_DIR}/pkg/${CASSANDRA_PKG} -C /opt/
  sudo ln -s /opt/apache-cassandra-${CASSANDRA_VERSION} ${CASSANDRA_HOME}

  if [ ! -e /etc/init.d/cassandra ] ; then
    sudo cp ${CASSANDRA_MODULE_DIR}/init-cassandra /etc/init.d/cassandra
    sudo chown root. /etc/init.d/cassandra
    sudo chmod +x /etc/init.d/cassandra
  fi

  sudo cp ${CASSANDRA_MODULE_DIR}/cassandra.yaml ${CASSANDRA_HOME}/conf/
  sudo sed -i.bak -e "s/\${ip_addr}/${IP_ADDRESS}/g" ${CASSANDRA_HOME}/conf/cassandra.yaml

  sudo cp ${CASSANDRA_MODULE_DIR}/cassandra-rackdc.properties ${CASSANDRA_HOME}/conf/
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
  sudo cp ${CASSANDRA_MODULE_DIR}/cassandra.sh /etc/profile.d/

  . /etc/profile
  sudo update-rc.d cassandra defaults >/dev/null
  sudo service cassandra restart >/dev/null
}
