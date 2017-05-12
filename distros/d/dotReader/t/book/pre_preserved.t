#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:nowrap

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
  'test_packages/pre_check/book.xml'
);
check_toc(['B']);

my $content = $book->get_content_by_id('B');
like($content, qr/1: *#\!\/usr\/local\/bin\/perl \n *2: \n *3: print/);
