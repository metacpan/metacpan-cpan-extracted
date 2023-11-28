#!/bin/bash

# cpan-dist-download-and-test - Download and test the provided cpan distribution using "purl" string

# (C) 2023, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>
# License MIT

set -e

PURL=$1

if [[ -z "$PURL" ]]; then
	echo "Usage: $0 PURL"
	echo ""
	echo "  Example:"
	echo "    $0 pkg:cpan/GDT/URI-PackageURL@2.04"
	echo ""
	exit 1
fi

eval $(purl-tool "$PURL" --env)

if [[ "$PURL_TYPE" != "cpan" ]]; then
	echo "[ERROR] Not 'cpan' type component"
	exit 1
fi

if [[ -z "$PURL_DOWNLOAD_URL" ]]; then
	echo "[ERROR] Missing PURL_DOWNLOAD_URL"
	exit 1
fi

echo "Download $PURL_NAME $PURL_VERSION"
wget $PURL_DOWNLOAD_URL

echo "Build and test module $PURL_NAME $PURL_VERSION"
tar xvf $PURL_NAME-$PURL_VERSION.tar.gz

cd $PURL_NAME-$PURL_VERSION

perl Makefile.PL
make && make test
