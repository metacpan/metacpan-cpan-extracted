#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
use utf8;
my $tf = Text::Fuzzy->new ('あいうえお☺');
print $tf->distance ('うえお☺'), "\n";

