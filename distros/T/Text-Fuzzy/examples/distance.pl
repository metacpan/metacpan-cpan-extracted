#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my $cat = Text::Fuzzy->new ('cat');
print $cat->distance ('cut'), "\n";
print $cat->distance ('cart'), "\n";
print $cat->distance ('catamaran'), "\n";
use utf8;
print $cat->distance ('γάτος'), "\n";
