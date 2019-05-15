#!/bin/sh
# objet: Verifie le nombre des conteneurs, des processus sur la plate-forme ou d'autres valeurs
# creation:     07/2018 Laurent Delatte
# modification: 04/2019 ajout parametres et envoi de mail
# args:  debug   : use test check inventory
#        int|rct : use alternative check inventory
#        distrib : to distribute AppCheck config files on remote VMs
# env:   for "-m" option only:  AppCheck.user file and SMTP* need configuration

BIN=.
ETC=.

[ "$LOGTAG" ] || LOGTAG=AppCheck
NbChn=2
distrib=0
config=prd-AppCheckIn
while getopts "e:dm?" opt; do
  case $opt in
  e) case $OPTARG in
     "debug") config=debug-AppCheckIn ;;
     "dev"|"int"|"rct"|"prd") config=$OPTARG-AppCheckIn ;;
     *) $0 -?
        exit 1 ;;
     esac ;;
  d) distrib=1 ;;
  m) mail=1 ;;
  *) echo "Usage: AppCheck.sh -e debug|dev|int|rct|prd> [ -m pour un format mail ] [ -d pour distribuer ]" >&2
     exit 1 ;;
  esac
done
[ -f $config ] || { echo "fichier de configuration $config absent" >&2; exit 1; }

cd $BIN
if [ $distrib == 1 ] ;then
  grep -v "^#" $ETC/$config |
  while read h l a c ;do
    [ $h == localhost ] && continue
    echo "ssh $h \"echo '# AppCheck config file' >$ETC/$config\""
    echo "scp AppCheck.sh $h:$BIN/"
  done >/tmp/AppCheck.tmp
  bash /tmp/AppCheck.tmp
fi

grep -v "^#" $ETC/$config |
while read h l a c ;do
  if [ $distrib == 1 ] ;then
    [ $h == localhost ] && continue
    echo "ssh $h \"echo 'localhost $l $a $c' >>$ETC/$config\""
  else
    [ "$h" == "localhost" ] && echo r="\`$c\`" || echo r="\`ssh $h $c\`"
    [ "$h" == "localhost" ] && sortie="logger -s -t $LOGTAG" || sortie=echo
    echo "[ \$r == $a ] || $sortie \"ERROR: Nombre d elements $(echo $config|sed 's/-.*//')-$l incorrect sur $h (\$r/$a)\""
  fi
done >/tmp/AppCheck.tmp
sed -i s/\$NbChn/$NbChn/g /tmp/AppCheck.tmp
if [ "$mail" != 1 ] ;then
  sh /tmp/AppCheck.tmp 2>&1
else
  sh /tmp/AppCheck.tmp >/dev/null 2>/tmp/AppCheck.log
  cat /tmp/AppCheck.log >&2
  if [ `cat /tmp/AppCheck.log|wc -l` -gt 0 ] ;then
    cat <<EOF >/tmp/AppCheck.txt
From: $SMTPFROM
To: $( echo $SMTPDEST |sed -e 's/--mail-rcpt \([^ ]*\) /\1,/g' -e 's/--mail-rcpt \([^ ]*\)$/\1/' )
Subject: $SMTPOBJECT
Content-Type: text/html; charset="utf8"
<html><body><pre>
EOF
    cat /tmp/AppCheck.log >>/tmp/AppCheck.txt
    echo "</pre></body></html>" >>/tmp/AppCheck.txt
    curl -m3 -s --url smtp://$SMTPHOST --user "$(cat $ETC/AppCheck.user)" --mail-from "$SMTPFROM" $SMTPDEST --upload-file /tmp/AppCheck.txt
  fi
fi
