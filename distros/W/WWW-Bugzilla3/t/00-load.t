#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Bugzilla3' );
}

diag( "Testing WWW::Bugzilla3 $WWW::Bugzilla3::VERSION, Perl $], $^X" );
