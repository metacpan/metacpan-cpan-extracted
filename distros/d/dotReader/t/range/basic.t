#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Range') };
BEGIN { use_ok('dtRdr::Highlight') };

my $book = bless({}, 'dtRdr::Book');
my $range = dtRdr::Range->create(node => $book, range => [0,10]);
ok($range);
isa_ok($range, 'dtRdr::Range');

my $highlight = dtRdr::Highlight->claim($range);
ok($highlight);
isa_ok($highlight, 'dtRdr::Highlight');
