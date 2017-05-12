use 5.006;
use strict;
use warnings;
use Test::More;
 
plan tests => 1;
 
BEGIN {
    use_ok( 'Tie::Anon' ) || print "Bail out!\n";
}
 
diag( "Testing Tie::Anon $Tie::Anon::VERSION, Perl $], $^X" );
