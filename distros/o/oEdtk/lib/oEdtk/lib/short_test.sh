#!/bin/sh
#set -x
#
# Objet : sauvegarde framework éditique
#
echo " le script doit etre lance par le user edtr00 ou edtp00" 
. $HOME/.profile

# variable
##########
#Verification de l'environnement
if [ `hostname` = "lmndv00" ];
then 
	basedir='/edtr01'
elif [ `hostname` = "lmndv05" ];
then
	basedir='/edtr01'
elif [ `hostname` = "lmnpr07" ];
then
	basedir='/opt/editique'

else 
	basedir='/edtp00'
fi

date=`date +%Y%m%d%H%M`
# on cree le repertoire de sauvegarde mep
mkdir -p $basedir/tmp/short_test/$date

cd $basedir/tmp/short_test/$date
echo Auto test de livraison 							>> $basedir/tmp/short_test/$date/short_test.log
date												>> $basedir/tmp/short_test/$date/short_test.log
echo $basedir/tmp/short_test/$date						>> $basedir/tmp/short_test/$date/short_test.log
echo $basedir/tmp/short_test/$date

perl $basedir/compo/app/LIS-AC016.pl 	$basedir/compo/app_test/LIS-AC016.dat 		test >> $basedir/tmp/short_test/$date/short_test.log
perl $basedir/compo/app/CTP-AC001.pl 	$basedir/compo/app_test/CTP-AC001.dat 		test >> $basedir/tmp/short_test/$date/short_test.log
perl $basedir/compo/app/DEV-CAMELEON.pl $basedir/compo/app_test/DEV-CAMELEON.dat 	test >> $basedir/tmp/short_test/$date/short_test.log
perl $basedir/compo/app/TST-SRVWEB.pl 	$basedir/compo/app_test/TST-SRVWEB.dat 		test >> $basedir/tmp/short_test/$date/short_test.log


if [ `hostname` != "lmnpr07" ];
then 

# attention, test de lotissement, bien nettoyer la base en sortant uniquement le test, surtout en prod
perl $basedir/compo/app/TST-LOTI.pl 	$basedir/compo/app_test/TST-LOTI.dat 		test --massmail >> $basedir/tmp/short_test/$date/short_test.log
perl $basedir/compo/lib/index_Run_lot.pl ED_REFIDDOC TST-LOTI								 >> $basedir/tmp/short_test/$date/short_test.log

fi

echo FIN
