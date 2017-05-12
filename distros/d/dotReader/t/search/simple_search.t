#!/usr/bin/perl

# A simple search                                   vim:ts=2:sw=2:et:sta

use warnings;
use strict;

use Test::More qw(no_plan);

use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Search::Book')};

my $book = ABook_new_1_0('test_packages/search_test/book.xml');

{
  my $searcher = dtRdr::Search::Book->new(
    book => $book,
    find => qr/sue/
  );
  my @results;
  while(my $hit = $searcher->next) {
    $hit->null and next;
    push(@results, $hit);
  }
  is(scalar(@results), 3, 'three hits');
  my @expects = (
    ['1',   16, 19],
    ['2.2', 44, 47],
    ['2.2', 53, 56],
  );
  foreach my $result (@results) {
    isa_ok($result, 'dtRdr::Search::Result', 'derived from result');
    isa_ok($result, 'dtRdr::Search::Result::Book', 'a book result');
    my $selection = $result->selection;
    ok($selection, 'got a selection');
    isa_ok($selection, 'dtRdr::Selection');
    my $expect = shift(@expects);
    is($selection->node->id, $expect->[0], 'node id');
    is($selection->a, $expect->[1], 'start position');
    is($selection->b, $expect->[2], 'end   position');
  }
}

