#!/usr/bin/perl

use warnings 'all';
use strict;
BEGIN {
   if (-d "lib") {
      use lib "./lib";
   } elsif (-d "../lib") {
      use lib "../lib";
   }
}

use Test::Inter;
my $ti = new Test::Inter $0;

sub func1 {
  my($tiutput) = @_;

  my @lines = ("First line",
               "Second line",
               "Third line");
  open(OUT,">$tiutput");
  foreach my $line (@lines) {
     print OUT "$line\n";
  }
  close(OUT);
}

sub func2 {
  my($input,$tiutput) = @_;
  open(IN,$input);
  open(OUT,">$tiutput");
  my @lines = <IN>;
  print OUT @lines;
  close(IN);
  close(OUT);
}

$ti->file(\&func1,'',         '','file.1.exp','No input');

$ti->file(\&func2,'file.2.in','','file.2.exp','File copy');

$ti->done_testing();

