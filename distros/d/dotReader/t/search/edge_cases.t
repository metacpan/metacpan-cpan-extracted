#!/usr/bin/perl

# Coverage for hits in weird places                 vim:ts=2:sw=2:et:sta

use warnings;
use strict;

use Test::More qw(no_plan);

use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Search::Book')};

my $book = ABook_new_1_0(
  'test_packages/search_test.edge_cases/book.xml'
);

{
  my $searcher = dtRdr::Search::Book->new(
    book => $book,
    find => qr/I/
  );
  my @results;
  while(my $hit = $searcher->next) {
    $hit->null and next;
    push(@results, $hit);
  }
  is(scalar(@results), 1, 'hits');
  foreach my $result (@results) {
    isa_ok($result, 'dtRdr::Search::Result', 'derived from result');
    isa_ok($result, 'dtRdr::Search::Result::Book', 'a book result');
  }
  is($results[0]->start_node->id, 'G', 'node match');
}
{
  my $searcher = dtRdr::Search::Book->new(
    book => $book,
    find => qr/K/
  );
  my @results;
  while(my $hit = $searcher->next) {
    $hit->null and next;
    push(@results, $hit);
  }
  is(scalar(@results), 1, 'hits');
  foreach my $result (@results) {
    isa_ok($result, 'dtRdr::Search::Result', 'derived from result');
    isa_ok($result, 'dtRdr::Search::Result::Book', 'a book result');
  }
  is($results[0]->start_node->id, 'G', 'node match');
}

