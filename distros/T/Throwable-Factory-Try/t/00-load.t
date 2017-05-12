#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Throwable::Factory::Try' ) || print "Bail out!\n";
}

diag( "Testing Throwable::Factory::Try $Throwable::Factory::Try::VERSION, Perl $], $^X" );
