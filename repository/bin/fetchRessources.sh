#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. $DIR/functions.sh

cd $PKG_DIR

if [ ! -e ${CASSANDRA_PKG} ]; then
 getCassandra 
else 
  echo "Cassandra package already exists."    
fi

if [ ! -e ${JDK_PKG} ]; then
  getJava
else
  echo "JDK package already exists."    
fi

exit 0
