#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Tie::Mounted');
}

diag("Testing Tie::Mounted $Tie::Mounted::VERSION, Perl $], $^X");
