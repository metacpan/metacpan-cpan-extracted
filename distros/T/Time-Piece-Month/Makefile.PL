use ExtUtils::MakeMaker;

use strict;
use warnings;

my $PACKAGE = "Time::Piece::Month";
my $LOCN    = "lib/Time/Piece/Month.pm";

WriteMakefile(
	AUTHOR        => 'Tony Bowden <tony@tmtm.com>',
	NAME          => $PACKAGE,
	ABSTRACT_FROM => $LOCN,
	VERSION_FROM  => $LOCN,
	PREREQ_PM     => {
		'Time::Piece::Range' => 0.9,
	},
	dist => {
		COMPRESS     => 'gzip -9',
		SUFFIX       => '.gz',
		DIST_DEFAULT => 'all tardist',
	},

);
