#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::ThrowAwayMail' ) || print "Bail out!\n";
}

diag( "Testing WebService::ThrowAwayMail $WebService::ThrowAwayMail::VERSION, Perl $], $^X" );
