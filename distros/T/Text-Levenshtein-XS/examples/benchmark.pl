#
# This file is part of Text-Levenshtein-XS
#
# This software is copyright (c) 2016 by Nick Logan.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use Text::Levenshtein::XS qw/distance/;
use Benchmark;
use utf8;

print "\n------------------------------------------------\n";

print "small strings\n";
timethis(1000000, 'distance("four","fuoru");'); 

print "------------------------------------------------\n";

print "medium strings\n";
timethis(1000000, 'distance("four" x 1000,"fuoru" x 1000);'); 

print "------------------------------------------------\n";

print "large strings\n";
timethis(1000000, 'distance("four" x 100000,"fuoru" x 100000);'); 

print "------------------------------------------------\n";

