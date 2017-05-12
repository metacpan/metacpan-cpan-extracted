#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use inc::testplan ();

my $book_uri;
BEGIN {
  $book_uri = 'books/test_packages/QuickStartGuide/quickstartguide.xml';
  unless(-e $book_uri) {
    plan skip_all => 'extra books/ dir not available';
  }
  else {
    inc::testplan->import(1,
        1 + # use_ok
        3 + # ABook
        2
    );
  }
}

use lib 'inc';
use dtRdrTestUtil::ABook;

BEGIN {use_ok('dtRdr::Selection');}

my $book = ABook_new_1_0($book_uri);
my $node = $book->find_toc($book->toc->id);
$book->get_content($node);
my $sel = $book->locate_string(
  $node,
  'ThoutReaderTM v 1.7 Copyright 2005, OSoft, Inc',
  'Quick Start Guide for ',
  '.'
  );
isa_ok($sel, 'dtRdr::Selection', 'isa selection');
is(
  $sel->get_selected_string,
  'ThoutReaderTM v 1.7 ...ght 2005, OSoft, Inc',
  'string result'
);



# vim:ts=2:sw=2:et:sta:syntax=perl
