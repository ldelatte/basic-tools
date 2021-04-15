#!/bin/bash
# objet: Sauvegarde la configuration de Jenkins
# creation:     04/2021 Laurent Delatte
# modification:
# args:  --: --
#
dir_vol=/var/lib/containers/storage/volumes/minikube/_data/data/jenkins-home-vol
dir_svg=/home/laurent/kube/jenkins_src/jenkins-home-vol-svg
[ -d $dir_svg ] || { echo "ERREUR: $dir_svg inexistant"; exit 1; }
#
cd $dir_svg
rm -rf * .* 2>/dev/null
#
cd $dir_vol
#
# plugins/
echo --- dir: plugins
cp -a plugins $dir_svg/
# jobs/<jobname>/config.xml
for f in jobs/* ;do
  echo --- dir: $f
  mkdir -p $dir_svg/$f
  cp -a $f/config.xml $dir_svg/$f/
done
# users/
echo --- dir: users
cp -a users $dir_svg/
# secrets/
echo --- dir: secrets
cp -a secrets $dir_svg/
echo --- files
# secret.key*
cp -a secret.key* $dir_svg/
# identity.key
cp -a identity.key* $dir_svg/
# *.xml
cp -a *.xml $dir_svg/
#
cd $dir_svg
chown -R --reference=plugins jobs
chown --reference=plugins .
touch __date_svg
