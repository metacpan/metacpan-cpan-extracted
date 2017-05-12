#!/bin/sh
# create notes with topics which then represents the corresponding
# directory structure. Depending on how many files the directory
# contains, the resulting note-database may become very large.
# It will then have thousands of notes!
STARTDIR=$1
case $STARTDIR in
	"")
    		echo "usage: stresstest.sh <directory>"
		exit 1
		;;
	*)
		LOCPFAD=`echo $STARTDIR | grep "^[a-zA-Z0-9.]"`
		case $LOCPFAD in
			"")
				#echo nix
				;;
			*)
				STARTDIR=`echo $STARTDIR | sed 's/^\.*//'`
				STARTDIR="`pwd`/$STARTDIR"
				STARTDIR=`echo $STARTDIR | sed 's/\/\//\//g'`
				;;
		esac
		;;	
esac


stress ()
{
    FILES=""
    for file in `ls $1|sort`
    do
	echo "$1/$file"
	if [ -d "$1/$file" ] ; then
	    stress "$1/$file"
	else
	    #echo "$1/" > /tmp/$$
	    #echo $file >> /tmp/$$
	    #`cat /tmp/$$ | note -`
	    FILES="$FILES $file"
	fi
    done	
    echo "$1/" > /tmp/$$
    echo "$FILES" >> /tmp/$$
    case $FILES in
    	"")
		;;
	*)	
    		RES=`cat /tmp/$$ | note -`
		;;
    esac		
    FILES=""
}

stress $STARTDIR
