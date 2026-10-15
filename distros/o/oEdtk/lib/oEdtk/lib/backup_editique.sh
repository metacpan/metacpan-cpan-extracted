#!/bin/sh
#set -x
#
# Objet : sauvegarde framework éditique
#
[[ `whoami` != "editique" ]] &&  echo " le script doit etre lance par le user editique" && exit 1
. $HOME/.profile

# variable
##########
date=`date +%Y%m%d%H%M`

# on cree le repertoire de sauvegarde mep
mkdir -p $HOME/mep/$date

basedir="$HOME/mep/$date"
date																			> $basedir/mep.editique.log
cd $HOME
echo $HOME


echo Sauvegarde de ./perl et ./texlive
echo  Tar de ./perl 
echo  Tar de ./perl																>> $basedir/mep.editique.log
tar -czvf $basedir/perl.old.tar ./perl												>> $basedir/mep.editique.log

echo  Tar de ./texlive/texmf.cnf ./texlive/texmf-local/tex/latex/local
echo  Tar de ./texlive/texmf.cnf ./texlive/texmf-local/tex/latex/local					>> $basedir/mep.editique.log
tar -czvf $basedir/texlive.old.tar ./texlive/texmf.cnf	./texlive/texmf-local/tex/latex/local	>> $basedir/mep.editique.log

echo Sauvegarde de /var/www/cgi-bin
echo Sauvegarde de /var/www/cgi-bin												>> $basedir/mep.editique.log
tar -czvf $basedir/web.edtk.old.tar /var/www/cgi-bin/*.cgi								>> $basedir/mep.editique.log

echo FIN
