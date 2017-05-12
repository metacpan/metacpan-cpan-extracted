#!/bin/csh

# run this script before making a new release, it will make sure doc in 
# top level directory is current 

pod2text ../lib/Text/SenseClusters.pm > ../README
pod2text ./CHANGES.pod > ../CHANGES
pod2text ./INSTALL.pod > ../INSTALL
pod2text ./FAQ.pod > ../FAQ
pod2text ./TODO.pod > ../TODO

