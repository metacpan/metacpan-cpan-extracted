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
  'test_packages/indexing_check_tags.1/book.xml'
);
check_toc(['A']);

like_test('A', ' 1 3 56 8 0 2');

{
  my $range = find_test(['A', '56 8 0', ' 1 3 ', ' 2', 'A', 5, 11]) or die;
  #warn "range is [", $range->a,", ", $range->b, "]\n";
  my $hl = highlight($range);
  highlight_test('A', '56 8 0');
  $book->delete_highlight($hl);
}
