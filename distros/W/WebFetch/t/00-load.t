#!perl -T

use Test::More tests => 10;

BEGIN {
	use_ok( 'WebFetch' );
	use_ok( 'WebFetch::Data::Store' );
	use_ok( 'WebFetch::Data::Record' );
	use_ok( 'WebFetch::Input::Atom' );
	use_ok( 'WebFetch::Input::PerlStruct' );
	use_ok( 'WebFetch::Input::RSS' );
	use_ok( 'WebFetch::Input::SiteNews' );
	use_ok( 'WebFetch::Output::Dump' );
	use_ok( 'WebFetch::Output::TT' );
	use_ok( 'WebFetch::Output::TWiki' );
}

diag( "Testing WebFetch $WebFetch::VERSION, Perl $], $^X" );
