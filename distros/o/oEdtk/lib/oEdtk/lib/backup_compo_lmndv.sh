#!/bin/sh
#set -x
#
# Objet : sauvegarde et backup framework éditique
#


# variable
##########
#Verification de l'environnement
if [ `hostname` = "lmndv00" ];
then 
	echo "  cleanup lmndv00"
elif [ `hostname` = "lmndv05" ];
then
	echo "  cleanup lmndv05"
else 
	echo " lancer uniquement ce script sur lmndv00 ou lmndv05"
	wait 
	exit 1
fi

basedir='/edtr01'
date=`date +%Y%m%d%H%M`
# on cree le repertoire de sauvegarde backup
mkdir -p $basedir/backup/$date

date																> $basedir/backup/$date/backup.compo.lmndv.log
cd $basedir

echo Cleanup de ./compo uniquement sur LMNDV
echo Cleanup de ./compo uniquement sur LMNDV								>> $basedir/backup/$date/backup.compo.lmndv.log
perl ./compo/lib/db_historicize_index.pl
perl ./compo/lib/index_Purge_DCLIB.pl
# FIN DE LA PARTIE À NE PAS FAIRE EN PRODUCTION

echo Sauvegarde de $basedir/compo vers $basedir/backup/$date/compo.old.tar
echo Sauvegarde de $basedir/compo vers $basedir/backup/$date/compo.old.tar		>> $basedir/backup/$date/backup.compo.lmndv.log
tar -czvf $basedir/backup/$date/compo.old.tar ./compo						>> $basedir/backup/$date/backup.compo.lmndv.log 

echo FIN
