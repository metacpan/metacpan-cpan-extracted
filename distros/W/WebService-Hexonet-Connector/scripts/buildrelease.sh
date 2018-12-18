#!/bin/bash
rm  WebService-Hexonet-Connector-v"$1".tar.gz >/dev/null 2>&1
make manifest && make tardist
cp WebService-Hexonet-Connector-v"$1".tar.gz WebService-Hexonet-Connector-latest.tar.gz
cp WebService-Hexonet-Connector-v"$1".tar.gz WebService-Hexonet-Connector.tar.gz