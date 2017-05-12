#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::SDDL' );
}

diag( "Testing Win32::SDDL $Win32::SDDL::VERSION, Perl $], $^X" );
