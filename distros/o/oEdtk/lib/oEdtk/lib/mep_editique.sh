#!/bin/sh
#set -x
#
# Objet : MEP framework éditique
#


# variable
##########
# Verfication du user de soumission
[[ `whoami` != "editique" ]] &&  echo " le script doit etre lance par le user editique" && exit 1

. $HOME/.profile
basedir='/opt/editique'

date								> $basedir/mep/mep.editique.log
cd $basedir

if [ -f $HOME/mep/perl.tar ] 
then
 echo Mise à jour du framework Perl à partir de $HOME/mep/perl.tar
 echo Mise à jour du framework Perl à partir de $HOME/mep/perl.tar		>> $basedir/mep/mep.editique.log
 rm -fR /opt/editique/perl/lib/site_perl/5.10.1/oEdtk					>> $basedir/mep/mep.editique.log
 tar -xvf $HOME/mep/perl.tar										>> $basedir/mep/mep.editique.log
else
 echo PAS de mise à jour de Perl
 echo PAS de mise à jour de Perl									>> $basedir/mep.compo.log
fi

if [ -f $HOME/mep/texlive.tar ] 
then
 echo Mise à jour du framework LaTeX à partir de $HOME/mep/texlive.tar
 echo Mise à jour du framework LaTeX à partir de $HOME/mep/texlive.tar	>> $basedir/mep/mep.editique.log
 tar -xvf $HOME/mep/texlive.tar									>> $basedir/mep/mep.editique.log

 echo refresh du framework LaTeX
 echo refresh du framework LaTeX									>> $basedir/mep/mep.editique.log
 $basedir/texlive/bin/i386-linux/texhash
else
 echo PAS de mise à jour de texlive
 echo PAS de mise à jour de texlive								>> $basedir/mep.compo.log
fi

if [ -f $HOME/mep/web.edtk.tar ] 
then
 #cd /var/www												>> $basedir/mep/mep.editique.log
 cd mep
 echo Mise à jour du service web à partir de $HOME/mep/web.edtk.tar
 echo Mise à jour du service web à partir de $HOME/mep/web.edtk.tar	>> $basedir/mep/mep.editique.log
 tar -xvf $HOME/mep/web.edtk.tar								>> $basedir/mep/mep.editique.log
else
 echo PAS de mise à jour du service web
 echo PAS de mise à jour du service web							>> $basedir/mep.compo.log
fi

cd $HOME
echo FIN
