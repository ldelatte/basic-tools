#!/bin/bash
# objet: Verifie le nombre des conteneurs et des processus sur la plate-forme
# creation: Laurent Delatte, 2018
# maj: ...
# args:
#       debug
#       rec     : alternative inventory
#       distrib : to distribute AppCheck config files on remote VMs
#
cd /usr/local/bin
NbChn=2
distrib=0
fichier=prd.AppCheckIn
[ "$1" = "debug" ] && fichier=ppp.AppCheckIn
[ "$2" = "debug" ] && fichier=ppp.AppCheckIn
[ "$1" = "rec" ] && fichier=rec.AppCheckIn
[ "$1" = "dev" ] && fichier=dev.AppCheckIn
[ "$1" = "distrib" ] && distrib=1
[ "$2" = "distrib" ] && distrib=1
if [ $distrib == 1 ] ;then
  grep -v "^#" /usr/local/etc/$fichier |
  while read h l a c ;do
    [ $h == localhost ] && continue
    echo "ssh $h \"echo '# AppCheck config file' >/usr/local/etc/$fichier\""
    echo "scp AppCheck.sh $h:/usr/local/bin/"
  done >/tmp/aaa
  bash /tmp/aaa
fi
grep -v "^#" /usr/local/etc/$fichier |
while read h l a c ;do
  if [ $distrib == 1 ] ;then
    [ $h == localhost ] && continue
    echo "ssh $h \"echo 'localhost $l $a $c' >>/usr/local/etc/$fichier\""
  else
    [ "$h" == "localhost" ] && echo r="\`$c\`" || echo r="\`ssh $h $c\`"
    [ "$h" == "localhost" ] && sortie='logger -s -t AppCheck' || sortie=echo
    echo "[ \$r == $a ] || $sortie \"ERROR: Nombre d elements $l incorrect sur $h (\$r/$a)\""
  fi
done >/tmp/aaa
sed -i s/\$NbChn/$NbChn/g /tmp/aaa
bash /tmp/aaa
