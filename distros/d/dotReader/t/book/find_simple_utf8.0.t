#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap:encoding=utf8

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };

use lib 'inc';

use dtRdrTestUtil::Expect;

my $book = open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check_utf8.0/book.xml'
);
check_toc(['A'..'C']);

use utf8; # allows the literal string below to be utf8
expect_test('A', '©™®');
expect_test('B', '™');
expect_test('C', '®');

wrange_test('A', 0, 3);
wrange_test('B', 1, 2);
wrange_test('C', 2, 3);
