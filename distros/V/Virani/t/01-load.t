#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Virani::Client' ) || print "Bail out!\n";
}

diag( "Testing Virani::Client $Virani::Client::VERSION, Perl $], $^X" );
