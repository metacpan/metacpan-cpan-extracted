#!/usr/bin/perl

use strict;
use warnings;

use inc::testplan(1,
  + 3 # ABook
  + 5 # metadata
);
use lib 'inc';
use dtRdrTestUtil::ABook;

my $book = ABook_new_1_0('test_packages/t1.short/book.xml');

{ # check the metadata
  can_ok($book, 'meta');
  my $meta = $book->meta;
  isa_ok($meta, 'dtRdr::Metadata::Book');
  my $as = $meta->annotation_server;
  isa_ok($as, 'dtRdr::Metadata::Book::annotation_server');
  is($as->id, 'a_local_server');
  is($as->uri, 'http://localhost:8085');
}

done;
# vim:ts=2:sw=2:et:sta
