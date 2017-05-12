#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Wx::Perl::PodEditor' );
}

diag( "Testing Wx::Perl::PodEditor $Wx::Perl::PodEditor::VERSION, Perl $], $^X" );
