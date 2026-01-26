#!/bin/bash

# sync-purl-spec - Sync the PURL specs
#
# (C) 2025, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

cd $(dirname $0) ; CWD=$(pwd)

GIT_REF=heads/main
GIT_REF=tags/v1.0.0

PURL_ARCHIVE_URL="https://github.com/package-url/purl-spec/archive/refs/$GIT_REF.zip"
PURL_ARCHIVE_FILE=$(mktemp)

rm -rf $CWD/lib/URI/PackageURL/types/*
mkdir -p $CWD/lib/URI/PackageURL/types/

wget -O $PURL_ARCHIVE_FILE $PURL_ARCHIVE_URL
unzip -j $PURL_ARCHIVE_FILE 'purl-spec-*/types/*-definition.json' -d $CWD/lib/URI/PackageURL/types

rm $PURL_ARCHIVE_FILE
