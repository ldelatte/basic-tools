#!/bin/ksh
# creation: Laurent Delatte 03/2019
# maj: ...
# objet: log multi conteneurs
# arg1: chaine
# arg2: [ anciennete ]
#
[ "$1" ] || { echo filtre obligatoire; exit 1; }
pid=""
docker container ls --format "{{.Names}}" --filter name=$1 |
if [ "$2" = "" ] ;then
  while read c;do
    docker container logs --since 5m -f $c &
    pid="$pid $!"
  done
else
  while read c;do
    docker container logs --since $2 $c
  done
fi
if [ "$pid" ] ;then
  read fin
  kill -15 $pid
fi
