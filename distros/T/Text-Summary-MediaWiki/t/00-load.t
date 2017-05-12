#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Text::Summary::MediaWiki' );
}

diag( "Testing Text::Summary::MediaWiki $Text::Summary::MediaWiki::VERSION, Perl $], $^X" );
