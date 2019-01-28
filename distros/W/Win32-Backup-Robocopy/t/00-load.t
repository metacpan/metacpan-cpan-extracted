#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Win32::Backup::Robocopy' ) || print "Bail out!\n";
}

diag( "Testing Win32::Backup::Robocopy $Win32::Backup::Robocopy::VERSION, Perl $], $^X" );
