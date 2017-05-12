#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Win32::Codepage::Simple' );
}

diag( "Testing Win32::Codepage::Simple $Win32::Codepage::Simple::VERSION, Perl $], $^X" );
