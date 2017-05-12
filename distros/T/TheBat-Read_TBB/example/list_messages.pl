#!perl -w
use strict;

  use TheBat::Read_TBB;
  my %ref;
  while(&Read_TBB("t/messages.tbb",\%ref)) {
    foreach my $k (keys %ref) {
      print "$k:\t" . $ref{$k} . "\n";
    }
  }
