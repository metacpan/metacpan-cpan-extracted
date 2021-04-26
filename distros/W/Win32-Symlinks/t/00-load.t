#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Win32::Symlinks' ) || print "Bail out!\n";
}

diag( "Testing Win32::Symlinks $Win32::Symlinks::VERSION, Perl $], $^X" );
