#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use inc::testplan(1,
  3 + # use_ok
  2 + # open_book
  4 +
  2 * 5
);

BEGIN {use_ok('dtRdr::Note');}
BEGIN {use_ok('dtRdr::Location');}
BEGIN {use_ok('dtRdr::Book::ThoutBook_1_0');}

my $book_uri = 'test_packages/indexing_check/book.xml';
(-e $book_uri) or die "missing '$book_uri' ?!";

my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'book');
isa_ok($book, 'dtRdr::Book');

$book->load_uri($book_uri);
my $toc = $book->toc;

{
  my $node = $toc->get_by_id('B');

  my $nt = dtRdr::Note->create(
    node  => $node,
    range => [0, 3],
    id    => 'foo'
  );
  isa_ok($nt, 'dtRdr::Note');
  is($nt->a, 0);
  is($nt->b, 3);
  ok($nt->id, 'has an ID (\''. $nt->id .'\')');
}
{ # now try with a range
  my $node = $toc->get_by_id('B');

  my $range = dtRdr::Range->create(node => $node, range => [0,3]);
  isa_ok($range, 'dtRdr::Range');
  my $nt = dtRdr::Note->create(
    node  => $node,
    range => $range,
    id    => 'foo'
  );
  isa_ok($nt, 'dtRdr::Note');
  is($nt->a, 0);
  is($nt->b, 3);
  ok($nt->id, 'has an ID (\''. $nt->id .'\')');
}
{ # and with implicit node-age
  my $node = $toc->get_by_id('B');

  my $range = dtRdr::Range->create(node => $node, range => [0,3]);
  isa_ok($range, 'dtRdr::Range');
  my $nt = dtRdr::Note->create(
    range => $range,
    id    => 'foo'
  );
  isa_ok($nt, 'dtRdr::Note');
  is($nt->a, 0);
  is($nt->b, 3);
  ok($nt->id, 'has an ID (\''. $nt->id .'\')');
}
