#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More tests => 3;

use Win32::Setupsup;

my $base = 0x20000000;

is(ERROR_TIMEOUT_ELAPSED,    $base + 14, 'ERROR_TIMEOUT_ELAPSED');
is(NOT_ENOUGTH_MEMORY_ERROR, $base +  1, 'NOT_ENOUGTH_MEMORY_ERROR');
is(UNKNOWN_PROPERTY_ERROR,   $base + 15, 'UNKNOWN_PROPERTY_ERROR');
