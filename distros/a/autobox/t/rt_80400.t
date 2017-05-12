#!/usr/bin/env perl

# Thanks to Tokuhiro Matsuno for the test case and patch
# https://rt.cpan.org/Ticket/Display.html?id=80400

use strict;
use warnings;

use Test::More tests => 1;

my $X;

END { $X->() }

use autobox INTEGER => __PACKAGE__;

sub test {
    is_deeply(\@_, [ 1, 42 ], 'autoboxed method called in END block');
};

$X = sub { 1->test(42) };
