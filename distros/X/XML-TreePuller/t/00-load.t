#!perl 

use Test::More tests => 1;

BEGIN {
    use_ok( 'XML::TreePuller' );
}

diag( "Testing XML::TreePuller $XML::TreePuller::VERSION, Perl $], $^X" );
