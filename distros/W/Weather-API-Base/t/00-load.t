#!perl
use 5.008;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Weather::API::Base' ) || print "Bail out!\n";
}

diag( "Testing Weather::API::Base $Weather::API::Base::VERSION, Perl $], $^X" );
