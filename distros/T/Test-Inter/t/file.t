#!/usr/bin/perl

use Test::Inter;
$o = new Test::Inter;

sub func1 {
  my($output) = @_;

  my @lines = ("First line",
               "Second line",
               "Third line");
  open(OUT,">$output");
  foreach my $line (@lines) {
     print OUT "$line\n";
  }
  close(OUT);
}

sub func2 {
  my($input,$output) = @_;
  open(IN,$input);
  open(OUT,">$output");
  my @lines = <IN>;
  print OUT @lines;
  close(IN);
  close(OUT);
}

$o->file(\&func1,'',         '','file.1.exp','No input');

$o->file(\&func2,'file.2.in','','file.2.exp','File copy');

$o->done_testing();

