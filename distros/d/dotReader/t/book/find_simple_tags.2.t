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
  'test_packages/indexing_check_tags.2/book.xml'
);
check_toc(['A']);

like_test('A', ' 1 3 56 8 0 2 4 6 8 0 2');

{
  my $range = find_test(['A', '1 3 56', '', ' 8 0 2 4 6', 'A', 0, 6]) or die;
  my $hl = highlight($range);
  highlight_test('A', '1 3 56');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['A', '56 8 0', '1 3 ', ' 2 4 6', 'A', 4, 10]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0');
  $book->delete_highlight($hl);
}
{
  my $range = find_test(['A', '56 8 0', '1 3 ', ' 2 4 6', 'A', 4, 10]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0');
  $book->delete_highlight($hl);
}
{ # check the "space between tags"
  my $range = find_test(['A', '56 8 0 2', '1 3 ', ' 4 6', 'A', 4, 12]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0 2');
  $book->delete_highlight($hl);
}
{ # check the "or no space between tags"
  my $range = find_test(['A', '56 8 02', '1 3 ', ' 4 6', 'A', 4, 12]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0 2');
  $book->delete_highlight($hl);
}
{ # check "I think there's space where there's not"
  my $range = find_test(['A', '5  6 8 02', '1 3 ', ' 4 6', 'A', 4, 12]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0 2');
  $book->delete_highlight($hl);
}
{ # check "I've never heard of space"
  my $range = find_test(['A', '56802', '13', '46', 'A', 4, 12]) or die;
  my $hl = highlight($range);
  highlight_test('A', '56 8 0 2');
  $book->delete_highlight($hl);
}
