#!/bin/sh
#set -x
#
# Objet : sauvegarde et MEP framework éditique
#
#Verfication du user de soumission
if [ `hostname` = "lmnpr07" ];
then 
	[[ `whoami` != "editique" ]] &&  echo " le script doit etre lance par le user editique" && exit 1
else 
	[[ `whoami` = "editique" ]] &&  echo " le script doit etre lance par le user edtp00 ou edtr01" && exit 1
fi
. $HOME/.profile

# variable
##########
date=`date +%Y%m%d%H%M`

# on cree le repertoire de sauvegarde mep
mkdir $HOME/backup/$date

edtkdir="/opt/editique"
backdir="$HOME/backup/$date"
date																> $backdir/mep.compo.log
cd $HOME
echo $HOME


echo Sauvegarde de ./compo vers $backdir/compo.old.tar
echo Sauvegarde de ./compo vers $backdir/compo.old.tar						>> $backdir/mep.compo.log
perl ./compo/lib/index_Purge_DCLIB.pl									>> $backdir/mep.compo.log
tar -czvf $backdir/compo.old.tar ./compo								>> $backdir/mep.compo.log 

if [ -f $edtkdir/mep/compo.tar ] 
then
 echo Mise à jour ./compo à partir de $edtkdir/mep/compo.tar
 echo Mise à jour ./compo à partir de $edtkdir/mep/compo.tar				>> $backdir/mep.compo.log
 tar -xvf $edtkdir/mep/compo.tar										>> $backdir/mep.compo.log
else
 echo PAS de mise à jour de Compo
 echo PAS de mise à jour de Compo										>> $backdir/mep.compo.log
fi

echo test de la configuration 
perl ./compo/lib/check_oEdtk_ini.pl

echo FIN