#!/bin/bash
DIR=$( dirname "$0" )
#Shuffle in parallel to check for test interdependency
prove -j 20 -s -I$DIR/lib $DIR/t "$@" || prove -v -I$DIR/lib $DIR/t "$@"
