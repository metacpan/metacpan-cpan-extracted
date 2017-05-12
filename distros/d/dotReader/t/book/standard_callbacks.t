#!/usr/bin/perl

use warnings;
use strict;

use lib 'inc';
use Test::More qw(no_plan);
use dtRdrTestUtil::ABook;

my $book = ABook_new_1_0('test_packages/check_img/book.xml');

my $node = $book->toc->get_by_id('A');
{
  my $content = $book->get_content($node);
  ok($content);
  ok($content =~ m/<img[^>]src="foo\.png"/, 'not modified');
}

dtRdr::Book->callback->set_img_src_rewrite_sub(
  sub {return($_[0]. ".bar.png")}
);
{
  my $content = $book->get_content($node);
  ok($content);
  ok($content =~ m/<img[^>]src="foo\.png\.bar\.png"/, 'modified');
}

# check the a_href_rewrite callback
$node = $book->toc->get_by_id('B');
{
  my $content = $book->get_content($node);
  ok($content);
  ok($content =~ m#<a[^>]href="pkg://check-img/A"#, 'href ok');
}

# TODO check the html head stuff

# vim:ts=2:sw=2:et:sta
