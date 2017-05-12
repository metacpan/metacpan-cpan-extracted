#!/bin/ksh -u
# Build the distribution tar file.

# Alain Williams, 2003
#	SCCS: @(#)BuildDistribution.sh 1.2 03/27/03 10:28:51


if [[ ! -r TemplateFill.pm ]]
then	echo "I can't see 'TemplateFill.pm'"
	exit 2
fi

Version=$( sed -n -e '/^our \$VERSION/s/^.*"\(.*\)".*/\1/p' TemplateFill.pm )

if [[ -z $Version ]]
then	echo "I can't get the version number from 'TemplateFill.pm'"
	exit 3
fi

case "$Version" in
	[0-9].[0-9]|[0-9].[0-9][0-9]|[0-9][0-9].[0-9]|[0-9][0-9].[0-9][0-9]|[0-9][0-9].[0-9][0-9][0-9]|[0-9][0-9].[0-9][0-9][0-9][0-9])
		:
		;;
	*)	echo "The version number doesn't look right '$Version'"
		exit 4
		;;
esac

# Nail in the module version number:
sed -e "s/MODVER/$Version/g" < README.in > README

# Different standards/naming conventions:
cp Hacks Changes

perl Makefile.PL || exit
make || exit
make dist
