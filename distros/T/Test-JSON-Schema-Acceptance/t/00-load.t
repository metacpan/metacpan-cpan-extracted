#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::JSON::Schema::Acceptance' ) || print "Bail out!\n";
}

diag( "Testing Test::JSON::Schema::Acceptance $Test::JSON::Schema::Acceptance::VERSION, Perl $], $^X" );
