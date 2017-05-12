#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my @words = (qw/who where what when why/);
my $tf = Text::Fuzzy->new ('whammo');
my @nearest = $tf->nearestv (\@words);
print "@nearest\n";
# Prints "who what"
