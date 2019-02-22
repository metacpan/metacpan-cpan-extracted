#!/usr/bin/perl -w

## dtatw-lb-encode.perl : fast regex hack approximation of dtatw-ensure-lb.perl
##  + insert <lb/> elements before every newline in //text//text()

my $outfile = @ARGV > 1 ? pop(@ARGV) : '-';
open(OUT, ">$outfile") or die("$0: open failed for output file '$outfile': $!");
select(OUT);

##-- slurp input file (for file heurstics)
local $/=undef;
my $buf = <>;
if ($buf =~ /<lb\b[^>]*>/) {
  ##-- file already contains <lb> elements: don't add any
  print $buf;
  exit 0;
}

##-- find largest substring covered by <text>..</text>
##  + not strictly correct if file contains multiple <text> elements
my ($off0,$off1);
for ($off0=index($buf,'<text'); $off0 >= 0; $off0=index($buf,'<text',$off0+1)) {
  last if (substr($buf,$off0,6) =~ m{^<text\b});
}
$off1 += 6;
for ($off1=rindex($buf,'</text'); $off1 > 0; $off1=rindex($buf,'</text',$off1-1)) {
  last if (substr($buf,$off1,7) =~ m{^</text\b});
}

##-- sanity check(s)
if ($off0 < 0 || $off1 < 0 || $off1 <= $off0) {
  ##-- no <text>...</text> target substring found
  print $buf;
  exit 0;
}

##-- tweak target buffer (in-place)
substr($buf,$off0,$off1-$off0) =~ s{(\r?\n)}{<lb/>$1}g;
print $buf;
