#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN { use_ok('dtRdr::Note') };
BEGIN { use_ok('dtRdr::Bookmark') };
BEGIN { use_ok('dtRdr::Highlight') };

use lib 'inc';

use dtRdrTestUtil::Expect;

my $book = open_book(
  'dtRdr::Book::ThoutBook_1_0',
  'test_packages/indexing_check/book.xml'
);
check_toc(['A'..'G']);

# we still need to do these to pre-populate the cache
expect_test('A', '0123456789');
expect_test('B', '123');
expect_test('C', '2');
expect_test('D', '456');
expect_test('E', '5');
expect_test('F', '8');
expect_test('G', '9');

# now we should be able to do a find and highlight

{ # highlights
  my $range = find_test('A  0123456789 - - A 0 10');
  my $hl = highlight($range);
  highlight_test('A', '0123456789');
  highlight_test('B', '123');
  highlight_test('C', '2');
  highlight_test('D', '456');
  highlight_test('E', '5');
  highlight_test('F', '8');
  highlight_test('G', '9');
  $book->delete_highlight($hl);
}
{ # notes
  my $range = find_test('A  0 - 1 A 0 1');
  my $nt = mk_note($range);
  note_test('A', '0');

}


