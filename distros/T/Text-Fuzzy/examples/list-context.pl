#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;

my @funky_words = qw/nice funky rice gibbon lice graeme garden/;
my $tf = Text::Fuzzy->new ('dice');
my @nearest = $tf->nearest (\@funky_words);

print "The nearest words are ";
print join ", ", (map {$funky_words[$_]} @nearest);
printf ", distance %d.\n", $tf->last_distance ();

# Prints out "The nearest words are nice, rice, lice."


