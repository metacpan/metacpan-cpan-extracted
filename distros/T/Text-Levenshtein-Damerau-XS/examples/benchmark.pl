use strict;
use warnings;
use Text::Levenshtein::Damerau::XS qw/xs_edistance/;
use Benchmark;
use utf8;

print "\n------------------------------------------------\n";

print "#xs small strings\n";
timethis(1000000, 'xs_edistance("four","fuoru");'); 

print "------------------------------------------------\n";

print "#xs medium strings\n";
timethis(1000000, 'xs_edistance("four" x 1000,"fuoru" x 1000);'); 

print "------------------------------------------------\n";

print "#xs large strings\n";
timethis(1000000, 'xs_edistance("four" x 100000,"fuoru" x 100000);'); 

print "------------------------------------------------\n";

