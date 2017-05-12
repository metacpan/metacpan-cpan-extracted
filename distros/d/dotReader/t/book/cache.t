#!/usr/bin/perl

# A simple search                                   vim:ts=2:sw=2:et:sta

use warnings;
use strict;

use Test::More qw(no_plan);

use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Search::Book')};

{ # no spaces here
  my $book = ABook_new_1_0('test_packages/indexing_check/book.xml');

  my $node = $book->find_toc('A');
  ok($node, 'got node A');
  my $chars = $book->create_node_characters($node);
  ok($chars, 'got characters');
  is($chars, '0123456789', 'match');
}

{ # this one is a bit trickier
  my $book = ABook_new_1_0('test_packages/indexing_check_tags.0/book.xml');

  {
    my $node = $book->find_toc('A');
    ok($node, 'got node A');
    my $chars = $book->create_node_characters($node);
    ok($chars, 'got characters');
    is($chars, '01 34 6 8 01', 'match');
  }
  {
    my $node = $book->find_toc('B');
    ok($node, 'got node B');
    my $chars = $book->create_NC($node);
    ok($chars, 'got characters');
    is($chars, ' 8 01', 'match');
    # do get_content and use that to verify against the definitive cache
    my $content = $book->get_content($node);
    ok($book->has_cached_NC($node), 'cache got made');
    my $cached = $book->get_cached_NC($node);
    is($cached, $chars, 'cache matches fabricated cache');
  }
}
# TODO more and harder tests against the definitive cache

# TODO cache rotation and tests for that
