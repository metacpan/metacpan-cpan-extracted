#!/bin/bash
cpan-upload -u "$CPAN_USER" -p "$CPAN_PASSWORD" --md5 --retries 3 --retry-delay 10 WebService-Hexonet-Connector-v"$1".tar.gz