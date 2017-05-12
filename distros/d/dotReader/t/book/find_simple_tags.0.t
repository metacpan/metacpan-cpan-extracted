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

my $book = open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check_tags.0/book.xml'
);
check_toc(['A'..'C']);

expect_test('A', '01 34 6 8  01');
#                 0123456789 01
expect_test('B', ' 8  01');
expect_test('C', ' 0');

{
  my $range = find_test(['A', '01 34 6 8 01', '', '', 'A', 0, 12]) or die;
  my $hl = highlight($range);
  highlight_test('A', '01 34 6 8 01');
  highlight_test('B', ' 8 01');
  highlight_test('C', '0');
  $book->delete_highlight($hl);
}

# create one in B and retest
{
  my $range = find_test(['B', '8 01', ' ', '', 'B', 1, 5]) or die;
  my $hl = highlight($range);
  highlight_test('B', '8 01');
  highlight_test('A', '8 01');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['A', '34 6 8', '01 ', ' 01', 'A', 3, 9]) or die;
  my $hl = highlight($range);
  highlight_test('A', '34 6 8');
  highlight_test('B', ' 8');
  highlight_test('C', '');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['A', '0', '34 6 8 ', '1', 'C', 0, 1]) or die;
  my $hl = highlight($range);

  highlight_test('A', '0');
  highlight_test('B', '0');
  highlight_test('C', '0');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['C', '0', ' ', '', 'C', 0, 1]) or die;
  my $hl = highlight($range);

  highlight_test('A', '0');
  highlight_test('B', '0');
  highlight_test('C', '0');
  $book->delete_highlight($hl);
}
