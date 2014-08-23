#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CASSANDRA_PKG=apache-cassandra-2.0.9-bin.tar.gz
JDK_PKG=jdk-8u20-linux-x64.tar.gz

CASSANDRA_URL=http://mirrors.koehn.com/apache/cassandra/2.0.9/${CASSANDRA_PKG}
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u20-b26/${JDK_PKG}

CURL=`which curl`

if [ -z ${CURL} ] ; then
  echo "Please install curl and put it in your PATH."
  exit 3
fi
cd $DIR/../repository
if [ ! -e ${CASSANDRA_PKG} ]; then
  ${CURL} -O ${CASSANDRA_URL}
else 
  echo "Cassandra package already exists."    
fi

if [ ! -e ${JDK_PKG} ]; then
  ${CURL} -b oraclelicense=accept-securebackup-cookie -O -L ${JDK_URL}
else
  echo "JDK package already exists."    
fi

exit 0
