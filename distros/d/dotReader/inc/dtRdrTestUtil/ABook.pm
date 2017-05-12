package main;

# Copyright (C) 2006 OSoft, Inc.
# License: GPL

use warnings;
use strict;
use Carp;

BEGIN {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::use_ok('dtRdr::Book::ThoutBook_1_0');
}

=head1 Functions

In package main.

=head2 ABook_new_1_0

  ABook_new_1_0($uri);

=cut

sub ABook_new_1_0 {
  my ($book_uri) = @_;
  my $book = dtRdr::Book::ThoutBook_1_0->new();
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  Test::More::ok($book, 'book');
  Test::More::isa_ok($book, 'dtRdr::Book');
  (-e $book_uri) or croak("missing '$book_uri' ?!");
  $book->load_uri($book_uri);

  return($book);
} # end subroutine new_1_0 definition
########################################################################

1;
# vim:ts=2:sw=2:et:sta
