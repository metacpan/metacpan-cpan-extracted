#!perl -T
use lib 'lib/';
use Test::More tests => 1;

BEGIN {
	use_ok( 'Vim::Snippet::Converter' );
}

diag( "Testing Vim::Snippet::Converter $Vim::Snippet::Converter::VERSION, Perl $], $^X" );
