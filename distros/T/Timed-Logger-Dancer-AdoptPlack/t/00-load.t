#!perl -T
use 5.16.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Timed::Logger::Dancer::AdoptPlack' ) || print "Bail out!\n";
}

diag( "Testing Timed::Logger::Dancer::AdoptPlack $Timed::Logger::Dancer::AdoptPlack::VERSION, Perl $], $^X" );
