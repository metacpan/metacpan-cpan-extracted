#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };

use lib 'inc';

use dtRdrTestUtil::Expect;

open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check_r0.1/book.xml'
);
check_toc(['A','C','C'..'E'], ['A'..'E']);

expect_test('A', '034');
expect_test('B', '2');
expect_test('C', '2');
expect_test('D', '3');
expect_test('E', '4');

# TODO highlight test and overlapping highlight test
