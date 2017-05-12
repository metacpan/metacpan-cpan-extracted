#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Win32::TRADOS::Languages' ) || print "Bail out!\n";
}

diag( "Testing Win32::TRADOS::Languages $Win32::TRADOS::Languages::VERSION, Perl $], $^X" );
