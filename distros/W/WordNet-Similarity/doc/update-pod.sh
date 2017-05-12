#!/bin/csh

# run this script before making a new release, it will make sure doc in 
# top level directory is current 

podchecker ./changelog.pod
podchecker ./install.pod
podchecker ./intro.pod
podchecker ./developers.pod  
podchecker ./todo.pod
podchecker ./config.pod    
podchecker ./modules.pod  
podchecker ./utils.pod

pod2text ./changelog.pod > ../CHANGES
pod2text ./install.pod > ../INSTALL
pod2text ./intro.pod > ../README

