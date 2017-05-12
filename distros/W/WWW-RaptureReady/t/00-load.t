#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::RaptureReady' );
}

diag( "Testing WWW::RaptureReady $WWW::RaptureReady::VERSION, Perl $], $^X" );
