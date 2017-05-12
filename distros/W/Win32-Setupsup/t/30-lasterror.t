#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 5;

use Win32::Setupsup;

is(Win32::Setupsup::GetLastError(),  0, 'no error yet');
is(Win32::Setupsup::SetLastError(3), 3, 'set error 3');
is(Win32::Setupsup::GetLastError(),  3, 'get error 3 back');
is(Win32::Setupsup::SetLastError(0), 0, 'set error 0');
is(Win32::Setupsup::GetLastError(),  0, 'error is reset');
