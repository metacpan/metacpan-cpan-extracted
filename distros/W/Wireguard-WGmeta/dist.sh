#!/bin/sh

VERSION=`cat VERSION`

perl Makefile.PL
make test

# test if version is updated everywhere
if ! grep -q $VERSION bin/wg-meta; then
    echo "ERROR: Version in bin/wg-meta is not updated"
    exit
fi
if ! grep -q $VERSION lib/Wireguard/WGmeta/Wrapper/Config.pm; then
    echo "ERROR: Version in Config.pm is not updated"
    exit
fi
if ! grep -q $VERSION lib/Wireguard/WGmeta/Wrapper/Show.pm; then
    echo "ERROR: Version in Show.pm is not updated"
    exit
fi

make CHANGES
make dist
cd .debian
make deb



