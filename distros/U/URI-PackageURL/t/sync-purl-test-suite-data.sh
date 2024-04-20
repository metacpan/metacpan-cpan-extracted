#!/bin/sh

# sync-purl-test-suite-data - Sync the PackageURL test suite data

# (C) 2024, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

cd $(dirname $0) ; CWD=$(pwd)

echo "Remove old PackageURL test suite file"
rm test-suite-data.json

echo "Download new PackageURL test suite file"
wget https://raw.githubusercontent.com/package-url/purl-spec/master/test-suite-data.json

exit 0
