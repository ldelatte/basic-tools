#!/bin/bash
# creation: Laurent Delatte 04/2019
# modifications: ...
# objet: fait un "docker container kill" sur les conteneurs d'un meme service

while getopts "e:s:h?" opt; do
  case $opt in
  e) ENV=$OPTARG
     [ "$ENV" = "int-" -o "$ENV" = "rct-" ] || { echo environnement incorrect; exit 1; } ;;
  s) SITE=$OPTARG
     [ "$SITE" = "da" -o "$SITE" = "di" ] || { echo site inconnu; exit 1; } ;;
  *) echo "Usage: redis_containers_restart.sh [ -e int-|rct-|<argument absent pour prod> ] [ -s da|di|<argument absent hors prod> ]" >&2
     exit 1 ;;
  esac
done
[ "$ENV" -o "$SITE" ] || { $0 -?; exit 1; }
[ "$ENV" -a "$SITE" ] && { $0 -?; exit 1; }

if [ "$ENV" ] ;then
  URL_DOCKER=https://ucp.docker
  COMPTE_DOCKER=dck
else
  URL_DOCKER=https://ucp.$SITE.docker
  COMPTE_DOCKER=pr-$SITE
fi

SERVICE='PR_redis'

WGET="wget --certificate=$HOME/ucp-bundle-$COMPTE_DOCKER/cert.pem --private-key=$HOME/ucp-bundle-$COMPTE_DOCKER/key.pem --no-check-certificate"

$WGET $URL_DOCKER/containers/json -O - | python -m json.tool | sed 's/,$//' |
awk '/"Id"/ { id=$2 }
     /"com.docker.swarm.service.name": "'$ENV$SERVICE'"/ { print id,$2 }' |
while read id nom ;do
  id=`echo $id|sed 's/"//g'`
  echo ">>>>> relance $id $nom"
  $WGET --post-data "" $URL_DOCKER/containers/$id/kill -O -
  sleep 60
done

echo "#### apres relances:"
$WGET $URL_DOCKER/containers/json -O - | python -m json.tool | sed 's/,$//' |
awk '/"Id"/ { id=$2 }
     /"com.docker.swarm.service.name": "'$ENV$SERVICE'"/ { print id,$2 }' |
while read id nom ;do
  id=`echo $id|sed 's/"//g'`
  echo ">>>>> relance $id $nom"
done
