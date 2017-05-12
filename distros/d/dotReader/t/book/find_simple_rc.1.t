#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN { use_ok('dtRdr::Highlight') };

use lib 'inc';

use dtRdrTestUtil::Expect;

open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check_rc.1/book.xml'
);
check_toc(['A'..'C']);

expect_test('A', '03');
expect_test('B', '12');
expect_test('C', '2');

{
  my $range = find_test('B 2 1 - C 0 1');
  my $hl = highlight($range);
  # this flexes the book's descendant_nodes method
  highlight_test('A', '');
  $hl->book->delete_highlight($hl);
}
{
  my $range = find_test('A 03 - - A 0 2');
  my $hl = highlight($range);
  # this flexes the book's ancestor_nodes method
  highlight_test('B', '');
  highlight_test('C', '');
}
