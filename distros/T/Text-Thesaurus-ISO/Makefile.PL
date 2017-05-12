#
# Makefile.PL for Text::Thesaurus::ISO
#
# Authors: Jon Knight and Martin Hamilton as part of the ROADS Project
#
# $Id$
#

$DISTNAME = 'Text-Thesaurus-ISO';
$VERSION  = "0.1";

use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => $VERSION,
#	DISTNAME  => $DISTNAME,
        NAME      => 'Text::Thesaurus::ISO',
	PMLIBDIRS => [qw(Text/Thesaurus)],
        'VERSION_FROM' => 'ISO.pm', # finds $VERSION 
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
 
	'clean'   => {FILES => join(" ", @clean)},
);

