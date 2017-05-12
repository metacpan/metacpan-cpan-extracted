#!/bin/bash

t="$(getopt -o hC -- "$@" )" || exit 99

usage() {
	echo "usage: $0 [-C] <dir> <url>";
}

eval set -- "$t"
unset t
CHECK=1;
while true
do
	case "$1" in 
		-h)
			usage;
			exit 0
			;;
		-C)
			CHECK=""
			;;
		--)
			shift
			break;
			;;
		*)
			echo "$1: internal error">&2
			exit 99
	esac
	shift
done



[ "$1" ] || { usage; exit 1; }
[ "$2" ] || { usage; exit 1; }

dir="$1"
url="$2"
perl="$PERL" || 'perl'
mkdir -p "$dir" || exit 1
cd "$dir" || exit 1
svn export "$url" || exit 1
(cd 'xsdsql/t' && rm -rf xml_#*) || exit 1
cd 'xsdsql' || exit 1

if [ "$CHECK" ]
then
	find . -name '*.p[lm]' | while read name
	do 
		$perl -c $name || exit 1
	done || exit 1
	find . -name '*.p[lm]' | xargs perlcritic || exit 1
	find . -name '*.p[lm]' | grep -v '/include\.pm' | xargs podchecker || exit 1	
fi || exit 1

$perl Makefile.PL PREFIX='/tmp' || exit 1

if [ "$CHECK" ]
then
	$perl tools/test_meta_yml.pl MYMETA.yml || exit 1
fi

mv MYMETA.yml META.yml || exit 1
rm -f Makefile
rm -f Makefile.old
find . | sed -e 's/^/\t/' > MANIFEST || exit 1
cd .. || exit 1
tar -cf xsdsql_20130411.tar xsdsql || exit 1 
gzip -9 xsdsql_20130411.tar || exit 1
rm -rf xsdsql || exit 1
exit 0

