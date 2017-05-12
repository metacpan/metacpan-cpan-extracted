#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

use lib 'inc';
use dtRdrTestUtil qw(error_catch);

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };

my $test_book = 'test_packages/duplicated_ids/book.xml';
(-e $test_book) or die "missing '$test_book' file!";

my $book = dtRdr::Book::ThoutBook_1_0->new();
ok($book, 'constructor');
my ($stderr, @ans) = error_catch( sub { $book->load_uri($test_book) });
ok($stderr, 'noise');
like($stderr, qr/has been duplicated/);
my $toc = $book->toc;
ok($toc, 'has toc anyway');
isa_ok($toc, 'dtRdr::TOC');
{
  my $found = $toc->get_by_id('C');
  isa_ok($found, 'dtRdr::TOC');
  my $content = $book->get_content($found);
  like($content, qr/>\s*C\s*</);
}
{
  my $found = $toc->get_by_id('C.##thout-autonumbered##.0');
  isa_ok($found, 'dtRdr::TOC');
  my $content = $book->get_content($found);
  like($content, qr/>\s*C.##thout-autonumbered##.0\s*</);
}
{
  my $found = $toc->get_by_id('C.##thout-autonumbered##.1');
  isa_ok($found, 'dtRdr::TOC');
  my $content = $book->get_content($found);
  like($content, qr/>\s*C.##thout-autonumbered##.1\s*</);
}

