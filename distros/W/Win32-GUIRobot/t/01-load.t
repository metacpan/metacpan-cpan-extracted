# $Id$

my $NUM;
BEGIN { $NUM = 6; }
use strict;
use Test::More tests => $NUM;

my $windoze = 1;

SKIP: {
	unless ( $^O =~ /win32|cygwin/i) {
		# has X11 ? 
		eval "use Prima;";
		if ( $@) {
			skip "This module won't run without X11", $NUM;
			$windoze = 0;
		}
	}

	eval "use Win32::GUIRobot qw(:all);";
	ok(not($@), 'use Win32::GUIRobot'); 
	warn $@ if $@;
	
	require Prima;
	ok(not($@), 'use Prima'); 
	warn $@ if $@;

	my $grab = ScreenGrab( 0, 0, 100, 100);
	ok( $grab, 'grab screen');

	$grab-> type( 8 ) if ($grab-> type & 0xff) < 8;

	my $halfgrab = $grab-> extract( 25, $grab-> height - 25 - 25, 25, 25);
	ok( $halfgrab, 'extract from image');

	# mark all non-halfgrab black so only one match is possible
	$grab-> put_image( 0, 0, $grab, rop::XorPut());
	$grab-> put_image( 25, $grab-> height - 25 - 25, $halfgrab);

	my ( $x, $y, $idx) = FindImage( $grab, $halfgrab);
	ok((defined($x) and defined($y) and ($x == 25) and ($y == 25)), 'find image');
	
	( $x, $y, $idx) = FindImage( $grab, [ $halfgrab, $halfgrab ]);
	ok((defined($x) and defined($y) and ($x == 25) and ($y == 25) and $idx == 0), 'find image in a list');
}

