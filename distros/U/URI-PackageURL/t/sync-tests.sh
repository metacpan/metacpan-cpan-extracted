#!/bin/bash

# sync-purl-tests - Sync the PURL and VERS tests
#
# (C) 2025, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

cd $(dirname $0) ; CWD=$(pwd)

GIT_REF=tags/v1.0.0

PURL_ARCHIVE_URL="https://github.com/package-url/purl-spec/archive/refs/$GIT_REF.zip"
PURL_ARCHIVE_FILE=$(mktemp)

GIT_REF=heads/main

VERS_ARCHIVE_URL="https://github.com/package-url/vers-spec/archive/refs/$GIT_REF.zip"
VERS_ARCHIVE_FILE=$(mktemp)

rm -rf $CWD/{purl,vers}/*

mkdir -p $CWD/{purl,vers}

# PURL tests
wget -O $PURL_ARCHIVE_FILE $PURL_ARCHIVE_URL
unzip -j $PURL_ARCHIVE_FILE 'purl-spec-*/tests/spec/*'  -d $CWD/purl/spec
unzip -j $PURL_ARCHIVE_FILE 'purl-spec-*/tests/types/*' -d $CWD/purl/types
rm $PURL_ARCHIVE_FILE

# VERS tests
wget -O $VERS_ARCHIVE_FILE $VERS_ARCHIVE_URL
unzip -j $VERS_ARCHIVE_FILE 'vers-spec-*/tests/*'  -d $CWD/vers
rm $VERS_ARCHIVE_FILE
