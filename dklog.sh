#!/bin/bash
# creation: Laurent Delatte 03/2019
# modifications: ...
# objet: log multi conteneurs

while getopts "f:m:h:?" opt; do
  case $opt in
    f)
      FILTRE=$OPTARG ;;
    m)
      ANC=${OPTARG}m ;;
    h)
      ANC=${OPTARG}h ;;
    *)
      echo "Usage: dklog.sh -f <nom partiel des conteneurs> [ -m <nb de minutes> | -h <nb d'heures> (defaut: 5m avec suivi) ]" >&2
      exit 1 ;;
  esac
done

[ "$FILTRE" ] || { $0 -?; exit 1; }

docker container ls --format "{{.Names}}" --filter name=$FILTRE |
if [ "$ANC" ] ;then
  while read c;do
    docker container logs --since $ANC $c
  done
else
  while read c;do
    docker container logs --since 5m -f $c &
    pid="$pid $!"
  done
  sleep 60
  kill -15 $pid
fi
