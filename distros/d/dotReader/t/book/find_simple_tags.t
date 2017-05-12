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
  'test_packages/indexing_check_tags/book.xml'
);
check_toc(['A'..'C']);

expect_test('A', '01 23 4 567');
#                 01234567890
expect_test('B', ' 567');
expect_test('C', '6');

{
  my $range = find_test(['A', '01 23 4 567', '', '', 'A', 0, 11]) or die;
  my $hl = highlight($range);
  highlight_test('A', '01 23 4 567');
  highlight_test('B', ' 567');
  highlight_test('C', '6');
  $book->delete_highlight($hl);
}

# create one in B and retest
{
  my $range = find_test(['B', '567', ' ', '', 'B',1, 4]) or die;
  my $hl = highlight($range);
  highlight_test('B', '567');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['A', '23 4 567', '01 ', '', 'A', 3, 11]) or die;
  my $hl = highlight($range);
  highlight_test('A', '23 4 567');
  highlight_test('B', ' 567');
  highlight_test('C', '6');
  $book->delete_highlight($hl);
}
