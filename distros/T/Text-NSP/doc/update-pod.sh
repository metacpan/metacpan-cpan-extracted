#!/bin/csh

# make all documentation changes to /Docs directory
# then run this to update top level read-only versions

pod2text CHANGES.pod > ../CHANGES
pod2text TODO.pod > ../TODO
pod2text README.pod > ../README
pod2text INSTALL.pod > ../INSTALL

# these are both somewhat out of date, so we won't put
# them in the top level, but we'll keep a text version
# in /docs for convenience 

pod2text USAGE.pod > ./USAGE
pod2text FAQ.pod > ./FAQ

