#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use lib 'inc';
use dtRdrTestUtil qw(slurp_data);

use Test::More (
  'no_plan'
  );

BEGIN { use_ok('dtRdr::Book') };

my $class = 'dtRdr::Book';

=note

grep '^sub ' lib/dtRdr/Book.pm | grep '\->NOT_IMPL' | \
  sed 's/^sub //' | sed 's/ .*//'

=cut

my @methods = slurp_data('methods_not_implemented.txt');

# just checking NOT_IMPLEMENTED() stuff here
foreach my $method (@methods) {
  eval { $class->$method("foo://bar") };
  like($@, qr/'$method' not implemented for class '$class'/, "NI $method");
}

{
  package dtRdr::Book::Whee;
  our @ISA = qw(dtRdr::Book);
}

{
  my $class = 'dtRdr::Book::Whee';
  foreach my $method (@methods) {
    eval { $class->$method("foo://bar") };
    like($@, qr/'$method' not implemented for class '$class'/, "NI $method");
  }
}


# maybe try overriding NOT_IMPLEMENTED() here at some point?
