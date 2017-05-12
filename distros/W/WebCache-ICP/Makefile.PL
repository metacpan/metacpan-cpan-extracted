# $Id: Makefile.PL,v 1.1 1999/04/27 16:48:21 martin Exp $

$DISTNAME = 'WebCache-ICP';
$VERSION  = "1.00";

use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => $VERSION,
	NAME      => $DISTNAME,
	PMLIBDIRS => [qw(WebCache)],
 
	'dist'    => {COMPRESS => 'gzip -9f',
		      SUFFIX   => '.gz', 
		      DIST_DEFAULT => 'all tardist',
		     },
 
	'clean'   => {FILES => join(" ", @clean)},
);

