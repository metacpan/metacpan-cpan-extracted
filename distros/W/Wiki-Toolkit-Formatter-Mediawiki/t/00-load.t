#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Wiki::Toolkit::Formatter::Mediawiki' );
	use_ok( 'Wiki::Toolkit::Formatter::Mediawiki::Link' );
}

diag( "Testing Wiki::Toolkit::Formatter::Mediawiki $Wiki::Toolkit::Formatter::Mediawiki::VERSION, Perl $], $^X" );
