#! /usr/bin/perl
#---------------------------------------------------------------------
# t/03-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Win32::Mutex');
}

diag("Testing Win32::Mutex $Win32::Mutex::VERSION");
