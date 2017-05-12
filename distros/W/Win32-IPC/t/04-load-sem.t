#! /usr/bin/perl
#---------------------------------------------------------------------
# t/04-load.t
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Win32::Semaphore');
}

diag("Testing Win32::Semaphore $Win32::Semaphore::VERSION");
