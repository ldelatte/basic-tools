#!/bin/bash
# creation: Laurent Delatte 04/2019
# modifications: ...
# objet: Fournit un etat des vulnerabilites des images du projet

while getopts "e:s:h?" opt; do
  case $opt in
  e) ENV=$OPTARG
     [ "$ENV" = "int-" -o "$ENV" = "rct-" ] || { echo environnement incorrect; exit 1; } ;;
  s) SITE=$OPTARG
     [ "$SITE" = "a" -o "$SITE" = "b" ] || { echo site inconnu; exit 1; } ;;
  *) echo "Usage: redis_containers_restart.sh [ -e int-|rct-|<argument absent pour prod> ] [ -s a|b|<argument absent hors prod> ]" >&2
     exit 1 ;;
  esac
done
[ "$ENV" -o "$SITE" ] || { $0 -?; exit 1; }
[ "$ENV" -a "$SITE" ] && { $0 -?; exit 1; }

if [ "$ENV" ] ;then
  URI_DOCKER=dtr....
  COMPTE_DOCKER=svc
  MP_DOCKER="xxx"
else
  URI_DOCKER=dtr.$SITE...
  COMPTE_DOCKER=ccc-$SITE
  MP_DOCKER="xxx"
fi
URL_DOCKER=https://$URI_DOCKER

token=`curl -s -u "$COMPTE_DOCKER":"$MP_DOCKER" "$URL_DOCKER/auth/token?service=$URI_DOCKER&scope=repository:depot:pull" | sed -e 's/.*access_token":"//' -e 's/",".*//'`

grep image: $HOME/...docker-compose-*$ENV*.yml |
sed -e 's/.*domaine.//' -e 's/:/ /' -e 's/"//' |
while read IMAGE TAG ;do
echo ======================================================================================================
curl -s -H "Authorization: Bearer $token" $URL_DOCKER/api/v0/imagescan/repositories/depot/$IMAGE/$TAG?detailed=true |
grep -e '"reponame": "' -e '"tag": "' -e '"critical": ' -e '"major": ' -e '"minor": ' -e '"sha256sum": "' -e '"component": "' -e '"version": "' -e '"cve": "' -e '"cvss": ' -e '"summary": "' |
sed -e 's/"//g' -e 's/,$//' |
awk '/reponame:|tag:|critical:|major:|minor:/ { print }
     /sha256sum:/ { print " ----", $1, $2 }
     /component:/ { comp=$2 }
     /version:/   { vers=$2 }
     /cve:/       { cve=$2 }
     /cvss:/       { cvss=$2 }
     /summary:/   { print "  >>>", comp, vers, ":", cve, "CVSS="cvss; print }'
done
