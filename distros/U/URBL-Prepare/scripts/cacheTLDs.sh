#!/bin/sh

BASE1='http://george.surbl.org/'
FILE2='two-level-tlds'
FILE3='three-level-tlds'

BASEW='http://spamassasin.googlecode.com/svn-history/r6/trunk/share/spamassassin/'
WHITE='25_uribl.cf'

MKDIR=`which mkdir`
PWD=`which pwd`
MV=`which mv`
CP=`which cp`
WGET=`which wget`

ME=`$PWD`

if [ $# -eq 0 ]; then
  echo SYNTAX:  $0 output_directory
  exit 1
elif [ ! -e $1 ]; then
  $MKDIR -p $1
elif [ ! -d $1 ]; then
  echo $1 exists and is not a directory
  exit 1
fi

cd $1

function RETRIEVE {
  base=$1
  in=$2
  out=$3

  STATUS=$($WGET -N  ${base}$in 2>&1)

# if not retrieving, SAVED will == 'retrieving', else it will be a long string
  SAVED=${STATUS##*not}
# if IS retrieving, long string will be truncated to [nnnnn/nnnnn]
  RV=${SAVED##*saved}

  if [ $RV != 'retrieving.' ]; then
    if [ -e $in ]; then
      $CP $in $out
    fi
  fi
}

RETRIEVE $BASE1 $FILE2 level2
RETRIEVE $BASE1 $FILE3 level3
RETRIEVE $BASEW $WHITE white

cd $ME
