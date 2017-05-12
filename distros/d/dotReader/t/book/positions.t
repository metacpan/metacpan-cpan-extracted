#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

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
  'test_packages/anno_check_nopos.0/book.xml'
);

my $toc = $book->toc;
my $g = $toc->get_by_id('G');

#warn $g->word_start, ", ", $g->word_end;
my $chars = $book->get_NC($g);
#warn "chars: '$chars', length: ", length($chars);

my @sets = (
  [0, 0],
  [1, 1],
  [2, 2],
  # 3 not valid
  [4, 2],
  [5, 3],
  [6, 4],
  # 7 not valid
  [8, 4],
  [9, 5],
);
foreach my $set (@sets) {
  my $p = $book->_NP_to_RP($g, $set->[0]);
  is($p, $set->[1], "check @$set");
}
