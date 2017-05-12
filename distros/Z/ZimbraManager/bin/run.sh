#!/bin/sh

`dirname $0`/zimbra-manager.pl prefork --pid-file=/tmp/zimbra-manager-prefork.pid --listen='http://*:13000'

# `dirname $0`/zimbra-manager.pl daemon --listen='http://*:13000'
