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
  'test_packages/indexing_check_rc.2/book.xml'
);
check_toc(['A'..'D']);

expect_test('A', '014');
expect_test('B', '1');
expect_test('C', '23');
expect_test('D', '3');
