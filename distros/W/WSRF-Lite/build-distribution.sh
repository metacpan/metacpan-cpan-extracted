#! /bin/sh


find ./ -name CVS -exec rm -fr {} \;

rm -i preForkContainer.pl

rm -i test/TestingCanOnlyProveTheExistenceOfBugs

rm -i modules/logs/*

rm -ir modules/Session/LB3D

rm -ir modules/Session/ServiceGroup

rm -i tests/testlog

#rm -i ./WSRF/SSLDaemon.pm

rm -i ./installer.pl

rm -ir blib

rm -i pm_to_blib

cp ./WSRF/SSLDaemon.pm ./lib/WSRF/

cp ./WSRF/Lite.pm ./lib/WSRF/

rm -i build-distribution.sh

find ./ -type f -print | sed -e 's/\.\///g' > MANIFEST
