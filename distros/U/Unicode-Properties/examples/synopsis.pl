#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use Unicode::Properties 'uniprops';
my @prop_list = uniprops ('☺'); # Unicode smiley face
print "@prop_list\n";

