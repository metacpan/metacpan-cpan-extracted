#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Wiki::Toolkit::Store::Mediawiki' );
}

diag( "Testing Wiki::Toolkit::Store::Mediawiki $Wiki::Toolkit::Store::Mediawiki::VERSION, Perl $], $^X" );
