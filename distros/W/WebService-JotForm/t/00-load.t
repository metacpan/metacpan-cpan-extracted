#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::JotForm' ) || print "Bail out!\n";
}

diag( "Testing WebService::JotForm $WebService::JotForm::VERSION, Perl $], $^X" );
