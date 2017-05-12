#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Win32::RunAsAdmin' ) || print "Bail out!\n";
}

diag( "Testing Win32::RunAsAdmin $Win32::RunAsAdmin::VERSION, Perl $], $^X" );
