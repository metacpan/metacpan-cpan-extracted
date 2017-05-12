#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my @to_check;
BEGIN {
  @to_check = (
    [
      'dtRdr::Book::ThoutBook_1_0',
      'books/test_packages/QuickStartGuide/quickstartguide.xml',
      '19d405df538bf655746ae38ad34efde3',
    ],
    [
      'dtRdr::Book::ThoutBook_1_0_jar',
      'books/test_packages/QuickStartGuide.jar',
      '19d405df538bf655746ae38ad34efde3',
    ],
  );
  unless((-e $to_check[0][1]) and (-e $to_check[1][1])) {
    plan skip_all => 'extra books/ dir not available';
  }
  else {
    plan 'no_plan';
  }
}

BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0') };
BEGIN { use_ok('dtRdr::Book::ThoutBook_1_0_jar') };

foreach my $row (@to_check) {
  check_book(@$row);
}

########################################################################
sub check_book {
  my ($class, $test_book, $expect) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  (-e $test_book) or die;
  my $book = $class->new;
  ok($book, 'constructor');
  ok($book->load_uri($test_book), 'load');
  can_ok($book, 'fingerprint');
  my $fp = $book->fingerprint;
  ok(defined($fp), 'got a fingerprint');
  is($fp, $expect, 'matches');
}

# vim:ts=2:sw=2:et:sta:nowrap
