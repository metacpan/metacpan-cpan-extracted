#!/bin/sh

# run this script before making a new release, it will make sure doc in 
# top level directory is current 

podchecker ./README.pod
podchecker ./CHANGES.pod
podchecker ./INSTALL.pod

pod2text ./README.pod > ../README
pod2text ./CHANGES.pod > ../CHANGES
pod2text ./INSTALL.pod > ../INSTALL

