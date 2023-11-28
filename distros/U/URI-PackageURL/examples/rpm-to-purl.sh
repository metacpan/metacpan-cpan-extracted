#!/bin/bash

# rpm-to-purl - Convert all installed RPM packags in purl string

# (C) 2023, Giuseppe Di Terlizzi <giuseppe.diterlizzi@gmail.com>
# License MIT

. /etc/os-release

PACKAGES=$(rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n')

while IFS= read -r LINE; do

  PKG_NAME=$(echo $LINE | cut -d ' ' -f1)
  PKG_VER=$(echo $LINE | cut -d ' ' -f2)
  PKG_ARCH=$(echo $LINE | cut -d ' ' -f3)

  purl-tool --type rpm \
            --namespace $ID \
            --name $PKG_NAME \
            --version $PKG_VER \
            --qualifier distro=$ID-$VERSION_ID \
            --qualifier arch=$PKG_ARCH

done <<< "$PACKAGES"
