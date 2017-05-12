#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my $cat = Text::Fuzzy->new ('cat');
print $cat->distance ('cut'), "\n";
# Prints 1
print $cat->distance ('cart'), "\n";
# Prints 1
print $cat->distance ('catamaran'), "\n";
# Prints 6
use utf8;
print $cat->distance ('γάτος'), "\n";
# Prints 5
