#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests=>1;

my @output = `$^X -Iblib/lib examples/simple_scan<examples/ss_comment.in`;
my @expected = map {"$_\n"} split /\n/,<<EOF;
1..1
ok 1 - Perl.org available [http://perl.org/] [/perl/ should match]
EOF
is_deeply(\@output, \@expected, "working output as expected");
