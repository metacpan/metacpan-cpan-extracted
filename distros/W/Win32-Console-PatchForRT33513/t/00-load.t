use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Win32::Console::PatchForRT33513' ) or print "Bail out!\n";
}

diag( "Testing Win32::Console::PatchForRT33513 $Win32::Console::PatchForRT33513::VERSION, Perl $], $^X" );
