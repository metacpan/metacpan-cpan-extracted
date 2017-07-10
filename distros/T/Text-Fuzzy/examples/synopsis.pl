#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my $tf = Text::Fuzzy->new ('boboon');
print "Distance is ", $tf->distance ('babboon'), "\n";
my @words = qw/the quick brown fox jumped over the lazy dog/;
my $nearest = $tf->nearestv (\@words);
print "Nearest array entry is $nearest\n";

