#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests=>1;

my @output = `$^X -Iblib/lib examples/simple_scan<examples/ss_blank.in`;
my @expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - Blank lines were ignored [http://perl.org/] [/perl/ should match]
EOF
is_deeply(\@output, \@expected, "working output as expected");
