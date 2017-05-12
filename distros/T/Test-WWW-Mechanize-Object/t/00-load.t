#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::WWW::Mechanize::Object' );
}

diag( "Testing Test::WWW::Mechanize::Object $Test::WWW::Mechanize::Object::VERSION, Perl $], $^X" );
