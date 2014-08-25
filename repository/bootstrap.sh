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

. ${REPOSITORY_DIR}/functions.sh

sudo sed -i 's/^mesg n$/tty -s \&\& mesg n/g' /root/.profile

if [ "$HOSTNAME" = "ops" ] ; then
  if [ ! -e /etc/init.d/opscenterd ] ; then
    initOpsCenter
  fi
  exit 0
fi

if [ -z ${DATACENTER} ] ; then
  echo "Datacenter name is not set!"
  exit 1
fi

if [ ! -e /opt/java  ] ; then

  if [ ! -e ${REPOSITORY_DIR}/${JDK_PKG} ] ; then
    getJava
  fi
  initJava  
fi

if [ ! -e /opt/cassandra ] ; then
  if [ ! -e ${REPOSITORY_DIR}/${CASSANDRA_PKG} ] ; then
    getCassandra  
  fi
  initCassandra
fi

exit 0
