#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
my $tf = Text::Fuzzy->new ('nopqrstuvwxyz');
# Prints 13, the correct value.
print $tf->distance ('abcdefghijklm'), "\n";
$tf->set_max_distance (10);
# Prints 11, one more than the maximum distance, because the search
# stopped when the distance was exceeded.
print $tf->distance ('abcdefghijklm'), "\n";
