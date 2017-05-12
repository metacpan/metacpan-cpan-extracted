#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'XML::Filter::RemoveEmpty' );
}

diag( "Testing XML::Filter::RemoveEmpty $XML::Filter::RemoveEmpty::VERSION, Perl $], $^X" );
