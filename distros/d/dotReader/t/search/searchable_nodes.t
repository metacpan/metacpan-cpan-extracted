#!/usr/bin/perl

# is this really a book test though?

use warnings;
use strict;

use lib 'inc';
use Test::More qw(no_plan);
use dtRdrTestUtil::ABook;

my $book = ABook_new_1_0('test_packages/search_test/book.xml');
my @nodes = $book->visible_nodes;
ok(scalar(@nodes), 'got nodes');
{
  my @expect = (
    'root',
    'INTRO',
    'first',
    'second',
    'whee',
    'first second',
    'second second',
  );
  is(scalar(@nodes), scalar(@expect), 'count');
  my @titles = map({$_->title} @nodes);
  is_deeply(\@titles, \@expect, 'expect check');
}

#warn join("\n  ", 'visible:', map({$_->title} @nodes)), "\n";

# vim:ts=2:sw=2:et:sta:nowrap
