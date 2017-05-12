#!perl -T

use Test::More tests => 1;

BEGIN {
    eval{
	use_ok( 'Wx::Perl::DirTree' );
    };
}

diag( "Testing Wx::Perl::DirTree $Wx::Perl::DirTree::VERSION, Perl $], $^X" );
