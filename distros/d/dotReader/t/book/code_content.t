#!/usr/bin/perl

use warnings;
use strict;

use lib 'inc';
use Test::More qw(no_plan);
use dtRdrTestUtil::ABook;

my $book = ABook_new_1_0('test_packages/copy_ok_check/book.xml');

my $node = $book->toc->get_by_id('1');

{
  my $cont = $book->get_content($node);
  ok($cont =~ m#\<a[^>]*href="dr://LOCAL/#, 'found a link');
}

my $content = $book->get_copy_content($node);
#warn $content;
ok($content, 'got content');

# TODO check the content

# vim:ts=2:sw=2:et:sta
