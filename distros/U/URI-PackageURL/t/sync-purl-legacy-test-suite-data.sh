#!/bin/sh

# sync-purl-test-suite-data - Sync the PackageURL "legacy" test suite data
#
# (C) 2024-2025, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>

cd $(dirname $0) ; CWD=$(pwd)

echo "Remove old PURL test suite file"
rm test-suite-data.json

echo "Download legacy PURL test suite file"
wget https://raw.githubusercontent.com/package-url/purl-spec/e56202efb16b943add2ae27b81a00efd25add47a/test-suite-data.json

exit 0
