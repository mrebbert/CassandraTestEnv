#! /bin/bash

REPOSITORY_DIR=$DIR/../repository

. $DIR/../repository/functions.sh

cd $REPOSITORY_DIR

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
