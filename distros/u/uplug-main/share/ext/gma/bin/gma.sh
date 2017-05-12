#!/bin/sh
APP_ROOT=`pwd`

PATH=${PATH}:/usr/java/jre1.3.1_01/bin
export PATH

CLASSPATH=${CLASSPATH}:../lib/gma.jar
export CLASSPATH

# most command line arguments for java program are optional
# but in the shell script they are hard coded as required
java gma.GMA $1 $2 $3 $4 $5 $6 $7 $8
