#!/bin/csh

# This script will compile and install the scorer2 program
# from the SemEval 2010 All Words Disambiguation Task. 

# it will place them in whatever directory name you provide
# this directory should be in your PATH - we don't do that
# automatically since that could have unexpected consequences
# on other of your programs, so you will need to update
# your PATH if you install these programs somewhere not
# currently in your PATH

# please be warned that this script does not do much in the
# way of error checking, so please check the messages issued
# by this script and verify that your install has succeeed
# if they seem to have failed, you will need to do manual
# installs of SVDPACKC and/or Cluto as described in INSTALL

if ($#argv != 1) then
       echo "Usage: $0 install_directory"
       echo "specify directory to install scorer2"
       echo "...directory must already exist"
       exit
endif

set OSNAME = `uname -s`
set INSTALLDIR = $1
set GCCVERSION = `gcc --version`
 
if (! -d $INSTALLDIR) then
        echo "$INSTALLDIR does not exist" 
	echo "please create this directory and resubmit"
	exit 1
endif

# remove any existing installations or copies of cluto 

rm -fr $INSTALLDIR/scorer2

# compile and run scorer2

echo "**************************************************"
echo "let's install the scorer2 program ..."
echo " "
echo "your gcc version is $GCCVERSION"
echo " "

cd scorer

make

cp scorer2 $INSTALLDIR

echo "if all has gone well, you have installed scorer2 in $INSTALLDIR"
echo "let's check...you should see the scorer2 program: scorer2. "
echo " " 

ls -lg $INSTALLDIR/scorer2

echo " " 
echo ".... end of External Software Installation for UMLS::SenseRelate ...."
echo " " 
echo "if you have some problem with this script, please save the output"
echo "and send it to bthomson at umn.edu for further assistance"
