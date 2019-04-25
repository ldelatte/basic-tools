#!/bin/sh
# objet: Verifie le nombre des conteneurs et des processus sur la plate-forme
# creation: Laurent Delatte, 07/2018
# maj: ajout parametres, 04/2019
# args:
#       debug
#       rec     : alternative inventory
#       distrib : to distribute AppCheck config files on remote VMs

BIN=/usr/local/bin
ETC=/usr/local/etc
NbChn=2
distrib=0
fichier=prd.AppCheckIn
while getopts "e:d?" opt; do
  case $opt in
  e) case $OPTARG in
     "debug") fichier=ppp.AppCheckIn ;;
     "dev"|"int"|"rct"|"prd") fichier=$OPTARG.AppCheckIn ;;
     *) $0 -?
        exit 1 ;;
     esac ;;
  d) distrib=1 ;;
  *) echo "Usage: AppCheck.sh -e debug|dev|int|rct|prd> [ -d pour distribuer ]" >&2
     exit 1 ;;
  esac
done
[ -f $fichier ] || { echo "fichier de configuration $fichier absent" >&2; exit 1; }

cd $BIN
if [ $distrib == 1 ] ;then
  grep -v "^#" $ETC/$fichier |
  while read h l a c ;do
    [ $h == localhost ] && continue
    echo "ssh $h \"echo '# AppCheck config file' >$ETC/$fichier\""
    echo "scp AppCheck.sh $h:$BIN/"
  done >/tmp/AppCheck.tmp
  bash /tmp/AppCheck.tmp
fi

grep -v "^#" $ETC/$fichier |
while read h l a c ;do
  if [ $distrib == 1 ] ;then
    [ $h == localhost ] && continue
    echo "ssh $h \"echo 'localhost $l $a $c' >>$ETC/$fichier\""
  else
    [ "$h" == "localhost" ] && echo r="\`$c\`" || echo r="\`ssh $h $c\`"
    [ "$h" == "localhost" ] && sortie='logger -s -t AppCheck' || sortie=echo
    echo "[ \$r == $a ] || $sortie \"ERROR: Nombre d elements $l incorrect sur $h (\$r/$a)\""
  fi
done >/tmp/AppCheck.tmp
sed -i s/\$NbChn/$NbChn/g /tmp/AppCheck.tmp
sh /tmp/AppCheck.tmp
