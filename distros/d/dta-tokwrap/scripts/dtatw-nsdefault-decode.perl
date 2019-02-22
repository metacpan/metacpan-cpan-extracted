#!/usr/bin/perl -w

my $outfile = @ARGV > 1 ? pop(@ARGV) : '-';
open(OUT, ">$outfile") or die("$0: open failed for output file '$outfile': $!");
select(OUT);

while (<>) {
  s|(<[^>]*\s)XMLNS=|${1}xmlns=|g;  ##-- restore default namespaces
  print;
}
