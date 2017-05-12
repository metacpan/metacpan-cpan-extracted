#!/bin/bash
DIR=$( dirname "$0" )
prove -v -I$DIR/lib $DIR/t/$1 || echo "**************************************************************************" && perl -I$DIR/lib $DIR/t/$1
